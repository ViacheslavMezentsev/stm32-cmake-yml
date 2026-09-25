# Configure-only archive fixtures

These `.a` files contain only the standard ar archive header (`!<arch>\n`).
They have no object members, symbols or MCU ABI. No compiler or archiver was run.
Tests exercise library path handling, including a directory containing a space.
Do not use these files as firmware libraries. They are intentionally tracked
fixtures despite the repository-wide `*.a` ignore rule.
