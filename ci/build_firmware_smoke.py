"""Build the semihosting fixtures inside the compiler image (one tool pair)."""
from firmware_cases import BUILD_PROFILES
import argparse
import json
import os
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
        lock = json.loads((root / 'ci/dependencies.lock.json').read_text())
        etl = next(source for source in lock['sources'] if source['name'].startswith('ETL-'))
        arduino = next(source for source in lock['sources'] if source['name'].startswith('Arduino-'))
        for profile in BUILD_PROFILES:
            is_arduino = profile == 'arduinoString'
            toolchain = str(root / 'tests/firmware/semihosting/arduino-toolchain.cmake') if is_arduino else '/opt/modules/stm32-cmake/cmake/stm32_gcc.cmake'
            build = Path(tempfile.mkdtemp(prefix=profile + '-', dir=output))
            build.chmod(0o755)  # Artifacts may be consumed by another container user.
            commands = [
                ['cmake', '-S', str(root / 'tests/firmware/semihosting'), '-B', str(build), '-G', 'Ninja',
                 f'-DSTM32_YML_FRAMEWORK_DIR={root}', f'-DCMAKE_TOOLCHAIN_FILE={toolchain}',
                 f'-DSMOKE_GIT_REVISION={report["git_revision"]}', f'-DSMOKE_GIT_DIRTY={report["git_dirty"]}',
                 f'-DSTM32_YML_PROFILE={profile}', f'-DSMOKE_ETL_INCLUDE={etl["destination"]}/include', '-DCMAKE_BUILD_TYPE=Debug', '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON'],
                ['cmake', '--build', str(build), '--parallel', '4'],
            ]
            if is_arduino:
                commands[0].append(f'-DSTM32_YML_OVERRIDE_arduino_core_path={os.path.relpath(arduino["destination"], root / "tests/firmware/semihosting")}')
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
            bare = profile.startswith('bare') or is_arduino
            cmsis_only = profile.startswith('cmsis') or profile in ('freertosQueue', 'freertosTasks')
            if bare:
                metadata.update(CMSIS_CORE='none', CMSIS_DEVICE='none')
            if bare or cmsis_only:
                metadata['HAL_VERSION'] = 'none'
            commands_db = json.loads((build / 'compile_commands.json').read_text())
            sources = [Path(c['file']).name for c in commands_db]
            all_commands = '\n'.join(c['command'] for c in commands_db)
            if bare:
                expected_sources = {'bare_startup.S', 'main.cpp'} | ({'arduino_string.cpp', 'heap.c', 'WString.cpp', 'itoa.c'} if is_arduino else set())
                if set(sources) != expected_sources or 'CMSIS' in all_commands or 'HAL_Driver' in all_commands:
                    raise ValueError('Bare mode unexpectedly includes CMSIS/HAL or vendor startup')
                if not all(flag in all_commands for flag in ('-mcpu=cortex-m3', '-mthumb', '-mfloat-abi=soft')):
                    raise ValueError('Missing explicit bare-metal CPU flags')
            else:
                if not any(name.startswith('startup_stm32f103') for name in sources):
                    raise ValueError('Missing CMSIS device startup')
                has_hal = any(name.startswith('stm32f1xx_hal') for name in sources)
                if has_hal == cmsis_only:
                    raise ValueError('Unexpected HAL source selection')
            if profile in ('cmsisLibrary', 'cmsisEtl'):
                required = {'weighted.c', 'transform.cpp', 'language_probe.c'}
                if not required <= set(sources) or ('etl_probe.cpp' in sources) != (profile == 'cmsisEtl'):
                    raise ValueError('Missing or unexpected library sources')
                for name in ('smoke_weighted', 'smoke_transform', 'smoke_language'):
                    if not re.search(rf'^.*\sT\s+{name}$', symbols, re.M):
                        raise ValueError(f'Missing linked library function: {name}')
                metadata.update(LIB_RESULT='123', C_LANGUAGE='11')
                if profile == 'cmsisEtl':
                    metadata.update(ETL_RESULT='14', ETL_TEXT='etl:14', ETL_VERSION=etl['name'].removeprefix('ETL-'))
            if profile in ('freertosQueue', 'freertosTasks'):
                rtos_source = 'freertos_queue.c' if profile == 'freertosQueue' else 'freertos_tasks.c'
                if not {'tasks.c', 'list.c', 'queue.c', 'port.c', 'heap_4.c', rtos_source} <= set(sources):
                    raise ValueError('Missing FreeRTOS kernel/port/heap sources')
                if any('cmsis_os' in name for name in sources):
                    raise ValueError('Unexpected CMSIS-RTOS wrapper')
                metadata['RTOS_VERSION'] = 'V10.3.1'
                if profile == 'freertosQueue':
                    metadata.update(RTOS_RESULT='46', RTOS_SCHEDULER='not-started', RTOS_HEAP='restored')
                else:
                    metadata.update(RTOS_REPLY='46', RTOS_SCHEDULER='running', RTOS_TICK='advanced',
                                    RTOS_TASK_MESSAGE='hello from sender')
                    # CMSIS vectors must select the real FreeRTOS exception handlers.
                    vectors = vector.read_bytes()
                    for slot, name in ((11, 'SVC_Handler'), (14, 'PendSV_Handler'), (15, 'SysTick_Handler')):
                        match = re.search(rf'^([0-9a-fA-F]+)(?:\s+[0-9a-fA-F]+)?\s+T\s+{name}$', symbols, re.M)
                        if not match or struct.unpack_from('<I', vectors, slot * 4)[0] != (int(match[1], 16) | 1):
                            raise ValueError(f'Incorrect RTOS vector: {name}')
            if is_arduino:
                metadata.update(ARDUINO_TEXT='arm32:123', ARDUINO_LENGTH='9')
                if any('/opt/modules/stm32-cmake' in c['command'] for c in commands_db):
                    raise ValueError('Arduino build unexpectedly uses stm32-cmake')
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
