"""Build the semihosting fixtures inside the compiler image (one tool pair)."""
from firmware_cases import BUILD_PROFILES
import argparse
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile
from firmware_crc import inspect_crc


def inspect_elf(path, vector):
    data = path.read_bytes()
    if data[:7] != b'\x7fELF\x01\x01\x01' or struct.unpack_from('<HH', data, 16) != (2, 40):
        raise ValueError('Expected a little-endian ELF32 ARM image')
    entry = struct.unpack_from('<I', data, 24)[0]
    sp, reset = struct.unpack_from('<II', vector.read_bytes())
    if not (0x20000000 < sp <= 0x20005000 and sp % 8 == 0):
        raise ValueError(f'Invalid initial stack pointer: {sp:#x}')
    if not (reset & 1 and 0x08000000 <= (reset & ~1) < 0x08010000 and entry == reset):
        raise ValueError(f'Invalid reset vector/entry: {reset:#x}/{entry:#x}')
    # Physical load addresses include the FLASH copy of initialized RAM data.
    offset = struct.unpack_from('<I', data, 28)[0]
    size, count = struct.unpack_from('<HH', data, 42)
    loads = []
    for index in range(count):
        kind, _, vaddr, paddr, filesz, memsz, _, _ = struct.unpack_from('<8I', data, offset + index * size)
        if kind != 1:
            continue
        if filesz and not (0x08000000 <= paddr < paddr + filesz <= 0x08010000):
            raise ValueError(f'Load image outside 64 KiB FLASH: {paddr:#x}/{filesz}')
        if memsz and not any(low <= vaddr < vaddr + memsz <= high for low, high in
                            ((0x08000000, 0x08010000), (0x20000000, 0x20005000))):
            raise ValueError(f'Segment outside F103C8 memory: {vaddr:#x}/{memsz}')
        loads.append({'vaddr': vaddr, 'paddr': paddr, 'filesz': filesz, 'memsz': memsz})
    if not any(segment['vaddr'] <= (entry & ~1) < segment['vaddr'] + segment['filesz'] for segment in loads):
        raise ValueError('Entry point is not backed by a loadable segment')
    return {'entry': entry, 'initial_sp': sp, 'reset_vector': reset, 'segments': loads}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    args.output.mkdir(parents=True, exist_ok=True)
    output = args.output.resolve()
    report = {'status': 'failed', 'cases': []}
    manifest = output / 'build-summary.json'
    manifest.write_text(json.dumps(report))  # Never reuse a stale successful manifest.
    try:
        git = ['git', '-c', f'safe.directory={root}', '-C', str(root)]
        report['git_revision'] = subprocess.check_output(git + ['rev-parse', 'HEAD'], text=True, timeout=30).strip()
        report['git_dirty'] = '1' if subprocess.check_output(git + ['status', '--porcelain'], text=True, timeout=30).strip() else '0'
        baseline = json.loads((root / 'tests/firmware/semihosting/expected-metadata.json').read_text())
        report['gcc'] = subprocess.check_output(['arm-none-eabi-gcc', '-dumpfullversion'], text=True, timeout=30).strip()
        report['cmake'] = subprocess.check_output(['cmake', '--version'], text=True, timeout=30).splitlines()[0]
        for profile in BUILD_PROFILES:
            build = Path(tempfile.mkdtemp(prefix=profile + '-', dir=output))
            build.chmod(0o755)  # Artifacts may be consumed by another container user.
            commands = [
                ['cmake', '-S', str(root / 'tests/firmware/semihosting'), '-B', str(build), '-G', 'Ninja',
                 f'-DSTM32_YML_FRAMEWORK_DIR={root}', '-DCMAKE_TOOLCHAIN_FILE=/opt/modules/stm32-cmake/cmake/stm32_gcc.cmake',
                 f'-DSMOKE_GIT_REVISION={report["git_revision"]}', f'-DSMOKE_GIT_DIRTY={report["git_dirty"]}',
                 f'-DSTM32_YML_PROFILE={profile}', '-DCMAKE_BUILD_TYPE=Debug', '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON'],
                ['cmake', '--build', str(build), '--parallel', '4'],
            ]
            for name, command in zip(('configure', 'build'), commands):
                with (build / (name + '.log')).open('w') as log:
                    subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
            elf = build / 'semihosting_smoke.elf'
            for extension in ('elf', 'bin', 'hex', 'map', 'lss'):
                if not (build / ('semihosting_smoke.' + extension)).stat().st_size:
                    raise ValueError(f'Empty {extension} artifact')
            with (build / 'readelf.log').open('w') as log:
                subprocess.run(['arm-none-eabi-readelf', '-h', '-l', '-S', '-A', str(elf)], stdout=log, stderr=subprocess.STDOUT, check=True, timeout=30)
            vector = build / 'vectors.bin'
            subprocess.run(['arm-none-eabi-objcopy', '--dump-section', f'.isr_vector={vector}', str(elf), str(build / 'inspection.elf')], check=True, timeout=30)
            structure = inspect_elf(elf, vector)
            symbols = subprocess.check_output(['arm-none-eabi-nm', '-S', '--defined-only', str(elf)], text=True, timeout=30)
            (build / 'symbols.log').write_text(symbols)
            metadata = dict(baseline, PROFILE=profile, CMAKE=report['cmake'].removeprefix('cmake version '),
                            GIT_REVISION=report['git_revision'], GIT_DIRTY=report['git_dirty'])
            bare = profile.startswith('bare')
            cmsis_only = profile.startswith('cmsis')
            if bare:
                metadata.update(CMSIS_CORE='none', CMSIS_DEVICE='none')
            if bare or cmsis_only:
                metadata['HAL_VERSION'] = 'none'
            commands_db = json.loads((build / 'compile_commands.json').read_text())
            sources = [Path(c['file']).name for c in commands_db]
            all_commands = '\n'.join(c['command'] for c in commands_db)
            if bare:
                if set(sources) != {'bare_startup.S', 'main.cpp'} or 'CMSIS' in all_commands or 'HAL_Driver' in all_commands:
                    raise ValueError('Bare mode unexpectedly includes CMSIS/HAL or vendor startup')
                if not all(flag in all_commands for flag in ('-mcpu=cortex-m3', '-mthumb', '-mfloat-abi=soft')):
                    raise ValueError('Missing explicit bare-metal CPU flags')
            else:
                if not any(name.startswith('startup_stm32f103') for name in sources):
                    raise ValueError('Missing CMSIS device startup')
                has_hal = any(name.startswith('stm32f1xx_hal') for name in sources)
                if has_hal == cmsis_only:
                    raise ValueError('Unexpected HAL source selection')
            for symbol, key, expected in [('_Min_Heap_Size', 'HEAP_SIZE', 0 if profile.endswith('Template') else 512),
                                          ('_Min_Stack_Size', 'STACK_SIZE', 2048 if profile.endswith('Template') else 1024)]:
                match = re.search(rf'^([0-9a-fA-F]+)\s+A\s+{symbol}$', symbols, re.M)
                if not match or int(match[1], 16) != expected:
                    raise ValueError(f'Incorrect linker reservation: {symbol}')
                metadata[key] = str(expected)
            if profile.endswith('Template'):
                generated = (build / 'STM32F103C8_FLASH.ld').read_text()
                if '@HEAP_SIZE@' in generated or '@STACK_SIZE@' in generated:
                    raise ValueError('Unexpanded linker template')
            for kind, section in [('data', 'D'), ('bss', 'B'), ('ctor', 'B')]:
                match = re.search(rf'^([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+{section}\s+smoke_{kind}_probe$', symbols, re.M)
                if not match or int(match[2], 16) != 4:
                    raise ValueError(f'Missing four-byte {section} symbol: smoke_{kind}_probe')
                metadata[kind.upper() + '_ADDRESS'] = f'{int(match[1], 16):08X}'
            trap = re.search(r'^([0-9a-fA-F]+)\s+T\s+smoke_exit_trap$', symbols, re.M)
            if not trap:
                raise ValueError('Missing semihosting exit trap')
            exit_trap = int(trap[1], 16)
            crc_metadata, corrupted, negative = inspect_crc(elf)
            metadata.update(crc_metadata)
            if profile == 'success':
                damaged = build / 'crc-corrupt.elf'
                damaged.write_bytes(corrupted)
                report['crc_negative'] = {'profile': 'crc-corrupt', 'elf': str(damaged.relative_to(output)),
                                          'metadata': dict(metadata, **negative), 'exit_trap': exit_trap}
            report['cases'].append({'profile': profile, 'elf': str(elf.relative_to(output)),
                                    'sources': sources, 'structure': structure, 'metadata': metadata, 'exit_trap': exit_trap})
            print(f'PASS build/ELF: {profile}', flush=True)
        report['status'] = 'passed'
    except (OSError, ValueError, KeyError, struct.error, subprocess.SubprocessError) as error:
        report['error'] = str(error)
    manifest.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
