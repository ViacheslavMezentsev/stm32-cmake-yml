"""Expected firmware targets and profiles shared by builders, runners and report validation."""
BUILD_PROFILES = ('success', 'failure', 'hang', 'bare', 'bareTemplate', 'cmsis', 'cmsisTemplate', 'cmsisLibrary', 'cmsisEtl', 'arduinoString', 'freertosQueue', 'freertosTasks', 'freertosExternal')
RUN_PROFILES = BUILD_PROFILES + ('crc-corrupt',)
PASS_PROFILES = frozenset(BUILD_PROFILES) - {'failure', 'hang'}
# Built and inspected on every tool pair; QEMU has no machine for these families,
# so they run only in Renode on minimal models (spec 8.8.5, TC-57);
# h503/h503bkp check the CRC image with and without initialized data outside
# FLASH (spec 4.15.9, TC-63).
BUILD_ONLY_PROFILES = ('h7', 'h5', 'h503', 'h503bkp')

# Firmware targets (spec 8.8.8): every target builds every profile of the
# semihosting fixture. 'qemu' is the machine (None: not runnable in QEMU) and
# 'qemu_part' the core QEMU reports there: code for Cortex-M0 runs on the
# Cortex-M3 netduino2, whose memory map fits F0 and F1. Renode uses a minimal
# model with the real core ('renode', in tests/firmware/renode).
TARGETS = {
    'f103': dict(mcu='STM32F103C8T6', config='stm32_config.yml', family='f1', platform='cortex-m3-smoke',
                 cpu_flags='-mcpu=cortex-m3;-mthumb;-mfloat-abi=soft', bare_cpu='-mcpu=cortex-m3',
                 qemu='netduino2', qemu_part='0xC23 -> Cortex-M3', renode='f103-smoke.repl', renode_part='0xC23 -> Cortex-M3',
                 flash=(0x08000000, 64 * 1024), ram=(0x20000000, 20 * 1024), rtos_version='V10.3.1'),
    'f030': dict(mcu='STM32F030R8T6', config='targets/f030/stm32_config.yml', family='f0', platform='cortex-m0-smoke',
                 cpu_flags='-mcpu=cortex-m0;-mthumb;-mfloat-abi=soft', bare_cpu='-mcpu=cortex-m0',
                 qemu='netduino2', qemu_part='0xC23 -> Cortex-M3', renode='f030-smoke.repl', renode_part='0xC20 -> Cortex-M0',
                 flash=(0x08000000, 64 * 1024), ram=(0x20000000, 8 * 1024), rtos_version='V10.0.1'),
    # F4 runs on the netduinoplus2 (STM32F405, Cortex-M4F): its FLASH and SRAM cover both parts.
    'f411': dict(mcu='STM32F411CEU6', config='targets/f411/stm32_config.yml', family='f4', platform='cortex-m4-smoke',
                 cpu_flags='-mcpu=cortex-m4;-mthumb;-mfpu=fpv4-sp-d16;-mfloat-abi=hard', bare_cpu='-mcpu=cortex-m4',
                 qemu='netduinoplus2', qemu_part='0xC24 -> Cortex-M4', renode='f4-smoke.repl', renode_part='0xC24 -> Cortex-M4',
                 flash=(0x08000000, 512 * 1024), ram=(0x20000000, 128 * 1024), rtos_version='V10.3.1'),
    'f401': dict(mcu='STM32F401CCU6', config='targets/f401/stm32_config.yml', family='f4', platform='cortex-m4-smoke',
                 cpu_flags='-mcpu=cortex-m4;-mthumb;-mfpu=fpv4-sp-d16;-mfloat-abi=hard', bare_cpu='-mcpu=cortex-m4',
                 qemu='netduinoplus2', qemu_part='0xC24 -> Cortex-M4', renode='f4-smoke.repl', renode_part='0xC24 -> Cortex-M4',
                 flash=(0x08000000, 256 * 1024), ram=(0x20000000, 64 * 1024), rtos_version='V10.3.1'),
    # G4 runs in Renode only, as recommended for this family; RAM counts SRAM1, SRAM2
    # and the CCM SRAM alias, contiguous from 0x20000000.
    'g431': dict(mcu='STM32G431CBU6', config='targets/g431/stm32_config.yml', family='g4', platform='cortex-m4-smoke',
                 cpu_flags='-mcpu=cortex-m4;-mthumb;-mfpu=fpv4-sp-d16;-mfloat-abi=hard', bare_cpu='-mcpu=cortex-m4',
                 qemu=None, qemu_part=None, renode='g4-smoke.repl', renode_part='0xC24 -> Cortex-M4',
                 flash=(0x08000000, 128 * 1024), ram=(0x20000000, 32 * 1024), rtos_version='V10.3.1'),
    'g474': dict(mcu='STM32G474CEU6', config='targets/g474/stm32_config.yml', family='g4', platform='cortex-m4-smoke',
                 cpu_flags='-mcpu=cortex-m4;-mthumb;-mfpu=fpv4-sp-d16;-mfloat-abi=hard', bare_cpu='-mcpu=cortex-m4',
                 qemu=None, qemu_part=None, renode='g4-smoke.repl', renode_part='0xC24 -> Cortex-M4',
                 flash=(0x08000000, 512 * 1024), ram=(0x20000000, 128 * 1024), rtos_version='V10.3.1'),
    # F7 runs in Renode only: QEMU has no Cortex-M7 machine with FLASH at 0x08000000.
    # RAM is DTCM, SRAM1 and SRAM2, contiguous from 0x20000000.
    'f746': dict(mcu='STM32F746ZGT6', config='targets/f746/stm32_config.yml', family='f7', platform='cortex-m7-smoke',
                 cpu_flags='-mcpu=cortex-m7;-mthumb;-mfpu=fpv5-sp-d16;-mfloat-abi=hard', bare_cpu='-mcpu=cortex-m7',
                 qemu=None, qemu_part=None, renode='f7-smoke.repl', renode_part='0xC27 -> Cortex-M7',
                 flash=(0x08000000, 1024 * 1024), ram=(0x20000000, 320 * 1024), rtos_version='V10.2.0'),
}
# Targets are enabled one family at a time, each with a full local check.
ENABLED_TARGETS = ('f103', 'f030', 'f411', 'f401', 'g431', 'g474', 'f746')
DEFAULT_TARGET = 'f103'


def case_name(target, profile):
    """Report name of a case: the F103 reference keeps plain profile names."""
    return profile if target == DEFAULT_TARGET else f'{target}:{profile}'


def split_case(name):
    """Return (target, profile) for a report case name."""
    target, separator, profile = name.partition(':')
    return (target, profile) if separator else (DEFAULT_TARGET, name)


BUILD_CASES = tuple(case_name(t, p) for t in ENABLED_TARGETS for p in BUILD_PROFILES)


def run_cases(emulator):
    """Expected run cases for an emulator: build cases plus one corrupted copy per target."""
    targets = [t for t in ENABLED_TARGETS if emulator != 'qemu' or TARGETS[t]['qemu']]
    return tuple(case_name(t, p) for t in targets for p in RUN_PROFILES)
