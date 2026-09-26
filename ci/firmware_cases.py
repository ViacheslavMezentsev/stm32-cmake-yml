"""Expected firmware profiles shared by builders, runners and report validation."""
BUILD_PROFILES = ('success', 'failure', 'hang', 'bare', 'bareTemplate', 'cmsis', 'cmsisTemplate', 'cmsisLibrary', 'cmsisEtl', 'arduinoString', 'freertosQueue', 'freertosTasks', 'freertosExternal')
RUN_PROFILES = BUILD_PROFILES + ('crc-corrupt',)
PASS_PROFILES = frozenset(BUILD_PROFILES) - {'failure', 'hang'}
# Built and inspected on every tool pair, not run: QEMU and Renode have no
# models for these families (spec 8.8.5, TC-57); h503/h503bkp check the CRC image
# with and without initialized data outside FLASH (spec 4.15.9, TC-63).
BUILD_ONLY_PROFILES = ('h7', 'h5', 'h503', 'h503bkp')
