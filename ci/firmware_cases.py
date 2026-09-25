"""Expected firmware profiles shared by builders, runners and report validation."""
BUILD_PROFILES = ('success', 'failure', 'hang', 'bare', 'bareTemplate', 'cmsis', 'cmsisTemplate')
RUN_PROFILES = BUILD_PROFILES + ('crc-corrupt',)
PASS_PROFILES = frozenset(BUILD_PROFILES) - {'failure', 'hang'}
