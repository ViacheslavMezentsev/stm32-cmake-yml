"""Build the semihosting fixtures inside the compiler image (one tool pair)."""
from firmware_cases import BUILD_ONLY_PROFILES, BUILD_PROFILES
import argparse
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import tempfile
from firmware_crc import crc32_words, inspect_crc


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


def compare_gap_fill(build, elf):
    """TC-64: the CRC image (spec 4.15.9) equals the 0.9.2 objcopy --gap-fill image."""
    image = next(build.glob('*_no_crc.bin'))
    reference = build / 'gap-fill.bin'
    subprocess.run(['arm-none-eabi-objcopy', '-O', 'binary', '--gap-fill', '0xFF', '--remove-section', '.checksum',
                    str(elf), str(reference)], check=True, timeout=60)
    if image.read_bytes() != reference.read_bytes():
        raise ValueError(f'CRC image differs from the objcopy --gap-fill image: {image.name}')


def flash_crc(elf, origin, length):
    """Independent host CRC of the FLASH load image without .checksum (TC-63)."""
    data = elf.read_bytes()
    shoff = struct.unpack_from('<I', data, 32)[0]
    shsize, shcount, names_index = struct.unpack_from('<HHH', data, 46)
    headers = [struct.unpack_from('<10I', data, shoff + i * shsize) for i in range(shcount)]
    names = data[headers[names_index][4]:]
    sections = {names[h[0]:].split(b'\0', 1)[0].decode(): h for h in headers}
    checksum = sections['.checksum']
    phoff = struct.unpack_from('<I', data, 28)[0]
    phsize, phcount = struct.unpack_from('<HH', data, 42)
    image = bytearray(b'\xFF' * length)
    top = 0
    outside = []
    for i in range(phcount):
        kind, offset, _, paddr, filesz, _, _, _ = struct.unpack_from('<8I', data, phoff + i * phsize)
        if kind != 1 or not filesz:
            continue
        if not origin <= paddr < paddr + filesz <= origin + length:
            outside.append(paddr)
            continue
        image[paddr - origin:paddr - origin + filesz] = data[offset:offset + filesz]
        top = max(top, paddr - origin + filesz)
    end = checksum[3] - origin
    stored = struct.unpack_from('<I', image, end)[0]
    if checksum[5] != 4 or end + 4 != top:
        raise ValueError('The .checksum section is not the last word of the FLASH image')
    computed = crc32_words(bytes(image[:end]))
    if stored != computed:
        raise ValueError(f'Stored CRC {stored:08X} differs from host CRC {computed:08X}')
    return stored, outside


def build_only(root, output):
    """Build H7/H5 firmware without simulators (TC-57) and the H503 CRC variants (TC-63)."""
    source = root / 'tests/firmware/buildonly'
    flash = {'h7': (0x08000000, 2048 * 1024), 'h5': (0x08000000, 2048 * 1024),
             'h503': (0x08000000, 128 * 1024), 'h503bkp': (0x08000000, 128 * 1024)}
    results = []
    for profile in BUILD_ONLY_PROFILES:
        build = Path(tempfile.mkdtemp(prefix=f'buildonly-{profile}-', dir=output))
        build.chmod(0o755)
        commands = [
            ['cmake', '-S', str(source), '-B', str(build), '-G', 'Ninja', f'-DSTM32_YML_FRAMEWORK_DIR={root}',
             '-DCMAKE_TOOLCHAIN_FILE=/opt/modules/stm32-cmake/cmake/stm32_gcc.cmake',
             f'-DSTM32_YML_PROFILE={profile}', '-DCMAKE_BUILD_TYPE=Debug'],
            ['cmake', '--build', str(build), '--parallel', '4'],
        ]
        for name, command in zip(('configure', 'build'), commands):
            with (build / (name + '.log')).open('w') as log:
                subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
        elf = build / 'buildonly_probe.elf'
        for extension in ('elf', 'bin', 'hex'):
            if not (build / ('buildonly_probe.' + extension)).stat().st_size:
                raise ValueError(f'Empty {extension} artifact: {profile}')
        data = elf.read_bytes()
        if data[:7] != b'\x7fELF\x01\x01\x01' or struct.unpack_from('<HH', data, 16) != (2, 40):
            raise ValueError(f'Expected a little-endian ELF32 ARM image: {profile}')
        origin, length = flash[profile]
        vector = build / 'vectors.bin'
        subprocess.run(['arm-none-eabi-objcopy', '--dump-section', f'.isr_vector={vector}', str(elf),
                        str(build / 'inspection.elf')], check=True, timeout=30)
        sp, reset = struct.unpack_from('<II', vector.read_bytes())
        entry = struct.unpack_from('<I', data, 24)[0]
        if not (0x20000000 <= sp < 0x30000000 and sp % 8 == 0):
            raise ValueError(f'Invalid initial stack pointer {sp:#x}: {profile}')
        if not (reset & 1 and origin <= (reset & ~1) < origin + length and entry == reset):
            raise ValueError(f'Invalid reset vector/entry {reset:#x}/{entry:#x}: {profile}')
        result = {'profile': profile, 'status': 'build-only', 'elf': str(elf.relative_to(output)),
                  'initial_sp': sp, 'reset_vector': reset}
        if profile.startswith('h503'):
            stored, outside = flash_crc(elf, origin, length)
            if bool(outside) != (profile == 'h503bkp'):
                raise ValueError(f'Unexpected load segments outside FLASH: {profile}')
            image = next(build.glob('*_no_crc.bin')).read_bytes()
            if len(image) > length:
                raise ValueError(f'CRC image larger than FLASH: {profile}')
            # The BIN artifact holds FLASH sections only (spec 4.14.2): the CRC
            # image plus the injected checksum, even with backup SRAM data.
            if (build / 'buildonly_probe.bin').read_bytes() != image + struct.pack('<I', stored):
                raise ValueError(f'BIN differs from the FLASH image with CRC: {profile}')
            if profile == 'h503':
                compare_gap_fill(build, elf)
            result['crc'] = f'{stored:08X}'
        results.append(result)
        print(f'PASS build-only: {profile}', flush=True)
    crcs = {r['crc'] for r in results if 'crc' in r}
    if len(crcs) != 1:
        raise ValueError(f'CRC differs with a section outside FLASH: {sorted(crcs)}')
    return results


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
        kernel = next(source for source in lock['sources'] if source['name'].startswith('FreeRTOS-Kernel-'))
        rtos_profiles = ('freertosQueue', 'freertosTasks', 'freertosExternal')
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
            if profile == 'freertosExternal':
                # FreeRTOS-Kernel outside STM32Cube (spec 4.8.6, TC-59).
                commands[0].append(f'-DFREERTOS_PATH={kernel["destination"]}')
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
            cmsis_only = profile.startswith('cmsis') or profile in rtos_profiles
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
            if profile in rtos_profiles:
                rtos_source = 'freertos_tasks.c' if profile == 'freertosTasks' else 'freertos_queue.c'
                if not {'tasks.c', 'list.c', 'queue.c', 'port.c', 'heap_4.c', rtos_source} <= set(sources):
                    raise ValueError('Missing FreeRTOS kernel/port/heap sources')
                if any('cmsis_os' in name for name in sources):
                    raise ValueError('Unexpected CMSIS-RTOS wrapper')
                kernel_files = [c['file'] for c in commands_db if Path(c['file']).name in ('tasks.c', 'port.c')]
                external = all(f.startswith(kernel['destination'] + '/') for f in kernel_files)
                if external != (profile == 'freertosExternal') or len(kernel_files) != 2:
                    raise ValueError('FreeRTOS kernel sources come from the wrong distribution')
                metadata['RTOS_VERSION'] = ('V' + kernel['name'].removeprefix('FreeRTOS-Kernel-')
                                            if profile == 'freertosExternal' else 'V10.3.1')
                if profile != 'freertosTasks':
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
            compare_gap_fill(build, elf)
            if profile == 'success':
                damaged = build / 'crc-corrupt.elf'
                damaged.write_bytes(corrupted)
                report['crc_negative'] = {'profile': 'crc-corrupt', 'elf': str(damaged.relative_to(output)),
                                          'metadata': dict(metadata, **negative), 'exit_trap': exit_trap}
            report['cases'].append({'profile': profile, 'elf': str(elf.relative_to(output)),
                                    'sources': sources, 'structure': structure, 'metadata': metadata, 'exit_trap': exit_trap})
            print(f'PASS build/ELF: {profile}', flush=True)
        report['build_only'] = build_only(root, output)
        report['status'] = 'passed'
    except (OSError, ValueError, KeyError, struct.error, subprocess.SubprocessError) as error:
        report['error'] = str(error)
    manifest.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
