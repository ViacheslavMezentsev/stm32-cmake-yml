# Message codes

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Message codes · [Русский](../../../ru/reference/0.9.2/messages.md)

The list is built from the `cmake/stm32_yml_messages_catalog.cmake` catalog by `ci/messages_reference.py`; do not edit it by hand. A code is `SCY-<class><number>`: class `I` is `STATUS`, `W` is `WARNING`, `E` is `FATAL_ERROR`. The output shows codes with `STM32_YML_MESSAGE_CODES=ON`; the `stm32_yml_messages.jsonl` and `stm32_yml_build_messages.jsonl` files always contain them. `{1}`…`{n}` are parameters. New in 0.10.0 (spec 4.16.5–4.16.13).

## 0xx — Core and configuration reading

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E001` | FATAL_ERROR | stm32-cmake-yml internal error: unknown message code '{1}'. |
| `SCY-E002` | FATAL_ERROR | stm32-cmake-yml internal error: message '{1}' expects {2} parameters, got {3}. |
| `SCY-E003` | FATAL_ERROR | The 'yq' tool is not found. Please install it. |
| `SCY-E004` | FATAL_ERROR | Configuration file not found: {1} |
| `SCY-E005` | FATAL_ERROR | yq failed to convert {1} to JSON. |
| `SCY-E006` | FATAL_ERROR | Invalid memory size format '{1}: {2}'. Use an integer number of bytes or an integer with an upper-case K or M suffix, for example: 0, 1536, 2K, 1M. |
| `SCY-E007` | FATAL_ERROR | mcu\_core: '{1}' is not valid for {2}: stm32-cmake does not split cores for this MCU. Remove mcu\_core from the configuration. |
| `SCY-E008` | FATAL_ERROR | {1} has several cores ({2}): set mcu\_core, for example 'mcu\_core: {3}'. |
| `SCY-E009` | FATAL_ERROR | mcu\_core: '{1}' is not valid for {2}. Valid values: {3}. |
| `SCY-E010` | FATAL_ERROR | Included file is missing or is a directory. Chain: {1} |
| `SCY-E011` | FATAL_ERROR | Configuration include cycle: {1} |
| `SCY-E012` | FATAL_ERROR | Invalid include in {1}: expected a path or a list of non-empty paths. |
| `SCY-E013` | FATAL_ERROR | Invalid addition '{1}': \_append and its base must be lists or empty values. |
| `SCY-E014` | FATAL_ERROR | Configuration {1} must contain a single mapping object. |
| `SCY-E015` | FATAL_ERROR | Unsupported configuration extension in {1}: expected .yml, .yaml or .toml. |
| `SCY-E016` | FATAL_ERROR | Multiple configuration files found: {1}. Set PROJECT\_CONFIG\_FILE explicitly. |
| `SCY-E017` | FATAL_ERROR | No stm32\_config.yml, stm32\_config.yaml or stm32\_config.toml found in {1}. |
| `SCY-W001` | WARNING | Unknown STM32\_YML\_LANG value '{1}': the language is chosen as for auto. Valid values: auto, ru, en. |
| `SCY-W002` | WARNING | The recommended parameter 'stm32\_cmake\_yml\_version' is not set in '{1}'. Set the framework version the configuration was written for (spec 4.2.3). |
| `SCY-W003` | WARNING | The framework version ({1}) is older than the configuration requires ({2}). Errors are possible. |
| `SCY-W004` | WARNING | The framework version ({1}) is newer than the configuration states ({2}). Update stm32\_cmake\_yml\_version. |
| `SCY-W005` | WARNING | Unknown value '{1}' of parameter '{2}'. Known values: {3}. '{4}' is applied. |
| `SCY-W006` | WARNING | Unknown value '{1}' of parameter '{2}'. Known values: {3}. The value is not used. |
| `SCY-W007` | WARNING | Unknown item '{1}' of parameter '{2}'. Known values: {3}. The item is skipped. |
| `SCY-I001` | STATUS | stm32-cmake-yml: {1}{2} |
| `SCY-I002` | STATUS | Configuration version: not set (stm32\_cmake\_yml\_version in {1}) |
| `SCY-I003` | STATUS | Configuration version: {1} (match) |
| `SCY-I004` | STATUS | Configuration version: {1}  (configuration is newer — update the framework!) |
| `SCY-I005` | STATUS | Configuration version: {1}  (framework is newer — update the configuration) |
| `SCY-I010` | STATUS | Verbose build output is enabled (CMAKE\_VERBOSE\_MAKEFILE=ON). |
| `SCY-I011` | STATUS | C-only flags:     {1} |
| `SCY-I012` | STATUS | C-only defines:   {1} |
| `SCY-I013` | STATUS | C++-only flags:   {1} |
| `SCY-I014` | STATUS | C++-only defines: {1} |
| `SCY-I020` | STATUS | Final project parameters (source: \[yml\]=configuration / \[ioc\]=CubeMX / \[auto\]=automatic): |
| `SCY-I021` | STATUS | MCU:        {2} {1} |
| `SCY-I022` | STATUS | Project:    {2} {1} |
| `SCY-I023` | STATUS | CubeFW:     {2} {1} |
| `SCY-I024` | STATUS | Heap Size:  {2} {1} bytes |
| `SCY-I025` | STATUS | Stack Size: {2} {1} bytes |
| `SCY-I026` | STATUS | FreeRTOS:   \[yml\] DISABLED (overridden in .yml) |
| `SCY-I027` | STATUS | FreeRTOS:   {1} Enabled |
| `SCY-I028` | STATUS | API:      {2} {1} |
| `SCY-I029` | STATUS | Port:     {2} {1} |
| `SCY-I030` | STATUS | FreeRTOS:   Disabled |
| `SCY-I031` | STATUS | Manual configuration mode (ioc\_file is not set). |
| `SCY-I032` | STATUS | Project name: {1} |
| `SCY-I033` | STATUS | Project languages are not set. The default is used: {1} |
| `SCY-I034` | STATUS | Project languages from the configuration: {1} |
| `SCY-I035` | STATUS | Configuration loaded from {1}. |
| `SCY-I036` | STATUS | Memory size '{1}' normalized to {2} bytes. |
| `SCY-I037` | STATUS | Parameter '{1}' was not set or was empty. The default value is used: '{2}'. |
| `SCY-I038` | STATUS | The MCU core is not set; the only core of {1} is used: {2}. |
| `SCY-I039` | STATUS | MCU core: {1} |
| `SCY-I040` | STATUS | Component versions: |
| `SCY-I041` | STATUS | {1}: {2} |
| `SCY-I042` | STATUS | Compiler: {1} {2} |
| `SCY-I043` | STATUS | Compiler: version unknown |
| `SCY-I044` | STATUS | {1}: version unknown{2} |

## 1xx — Profiles

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E101` | FATAL_ERROR | Pass -DSTM32\_YML\_PROFILE=&lt;name&gt; to select a profile. |
| `SCY-W101` | WARNING | Profile '{1}' is not found in the configuration. See the 'profiles:' section of {2} for the available profiles. |
| `SCY-W102` | WARNING | The inline 'profiles:' section is ignored (profiles: {1}): profiles\_file '{2}' is set and profiles are taken only from it. Move the profiles you need to the external file or remove the inline section. |
| `SCY-W103` | WARNING | Profiles file not found: {1} |
| `SCY-I101` | STATUS | Applying build profile: '{1}' |
| `SCY-I102` | STATUS | \[profile\] {1} = {2} |
| `SCY-I103` | STATUS | \[profile +\] {1} += {2} |
| `SCY-I104` | STATUS | \[override\] {1} = {2} |
| `SCY-I105` | STATUS | CMake overrides applied: {1}. |
| `SCY-I106` | STATUS | Available build profiles: |
| `SCY-I107` | STATUS | - {1} |
| `SCY-I108` | STATUS | No build profiles are defined in the configuration. |
| `SCY-I109` | STATUS | Loading profiles from the external file: {1} |

## 2xx — IOC

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E201` | FATAL_ERROR | The specified .ioc file is not found: {1} |
| `SCY-I201` | STATUS | 'ioc\_file' is set. Reading data from: {1} ... |
| `SCY-I202` | STATUS | Using CustomerFirmwarePackage: family={1}, version={2} |
| `SCY-I203` | STATUS | Path: {1} |

## 3xx — Sources and modules

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E302` | FATAL_ERROR | Project directory '{1}' clashes with the \_deps/ build directory of out-of-tree dependencies. Rename it: out-of-tree directories are built in \_deps/ (spec 4.6.8). |
| `SCY-W301` | WARNING | Custom library not found and ignored: {1} |
| `SCY-W302` | WARNING | Source '{1}' not found and ignored. |
| `SCY-I301` | STATUS | Adding custom library: {1} |
| `SCY-I302` | STATUS | Custom system file found. Override: {1} |
| `SCY-I303` | STATUS | Custom startup file found. Override: {1} |
| `SCY-I304` | STATUS | Out-of-tree directory {1} is built in {2} |

## 4xx — CMSIS, HAL, FreeRTOS

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E401` | FATAL_ERROR | STM32Cube directory not found: {1} |
| `SCY-E402` | FATAL_ERROR | No package for family {1} found in {2} |
| `SCY-E403` | FATAL_ERROR | Could not determine the version from the directories found for {1}. |
| `SCY-E404` | FATAL_ERROR | Could not determine the HAL/CMSIS driver paths. Check 'cubefw\_package'. |
| `SCY-E405` | FATAL_ERROR | use\_hal: true requires use\_cmsis: true. |
| `SCY-E406` | FATAL_ERROR | HAL component '{1}' (hal\_components) is not found for family {2}: there is no target {3}. Check the driver name in the STM32Cube {2} package. |
| `SCY-E407` | FATAL_ERROR | HAL component '{1}' (hal\_components) is not found for family {2} (core {3}): there is no target {4}. Check the driver name in the STM32Cube {2} package. |
| `SCY-E408` | FATAL_ERROR | Several FreeRTOS ports found: '{1}' and '{2}'. |
| `SCY-E409` | FATAL_ERROR | No port found in 'freertos\_components' (for example, 'ARM\_CM4F'). |
| `SCY-E410` | FATAL_ERROR | freertos\_version: external requires a FreeRTOS path: set FREERTOS\_PATH (-DFREERTOS\_PATH=... or an environment variable) to a FreeRTOS-Kernel directory or to Middlewares/Third\_Party/FreeRTOS of an STM32Cube package. |
| `SCY-E411` | FATAL_ERROR | freertos\_version: external: FreeRTOS.h and tasks.c are not found in FREERTOS\_PATH '{1}'. Expected a FreeRTOS-Kernel layout (include/, portable/GCC/&lt;port&gt;) or a Cube tree (Source/...). |
| `SCY-E412` | FATAL_ERROR | freertos\_version: external: port '{1}' files are not found in FREERTOS\_PATH '{2}' (portable/GCC/{1}). |
| `SCY-E413` | FATAL_ERROR | FreeRTOS component '{1}' (freertos\_components) is not found: there is no target {2} in the {3} namespace. |
| `SCY-E414` | FATAL_ERROR | cmsis\_rtos\_api: {1}: the CMSIS-RTOS wrapper is not found (there is no target {2}). Its sources come from Middlewares/Third\_Party/FreeRTOS of the STM32Cube {3} package and require use\_cmsis: true; the package may have no FreeRTOS (for example, H5, U5). Use cmsis\_rtos\_api: none. |
| `SCY-E415` | FATAL_ERROR | STM32Cube package {1} for family {2} not found: {3}. Install the package or set cubefw\_package: auto. |
| `SCY-W401` | WARNING | The framework table has no FreeRTOS port for '{1}'; ARM\_CM4F is used. Set freertos\_components explicitly. |
| `SCY-I401` | STATUS | 'auto' mode: looking for drivers... |
| `SCY-I402` | STATUS | Local drivers found in '{1}'. They are used. |
| `SCY-I403` | STATUS | STM32Cube MCU Firmware Package: {1} |
| `SCY-I404` | STATUS | No local drivers found. Looking for the latest version in the user repository... |
| `SCY-I405` | STATUS | Using the STM32Cube FW version found: {1} |
| `SCY-I406` | STATUS | Using the specified STM32Cube FW version: {1} |
| `SCY-I407` | STATUS | Automatic CMSIS integration is enabled. |
| `SCY-I408` | STATUS | Automatic HAL/LL component integration is enabled. |
| `SCY-I409` | STATUS | Automatic HAL/LL component integration is disabled. |
| `SCY-I410` | STATUS | Automatic FreeRTOS integration is enabled. |
| `SCY-I411` | STATUS | FreeRTOS port: {1} |
| `SCY-I412` | STATUS | FreeRTOS: {2} added to port {1} |
| `SCY-I413` | STATUS | CMSIS-RTOS API {1} wrapper added. |

## 5xx — Arduino

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E501` | FATAL_ERROR | \[arduino\] arduino.core\_path is not set in stm32\_config.yml.<br>Set the path to the Arduino\_Core\_STM32 folder relative to the project root:<br>  arduino:<br>    core\_path: "modules/Arduino\_Core\_STM32" |
| `SCY-E502` | FATAL_ERROR | \[arduino\] Arduino Core STM32 folder not found: {1}<br>Check arduino.core\_path in stm32\_config.yml.<br>In CI make sure the modules/Arduino\_Core\_STM32 symlink or folder exists. |
| `SCY-E503` | FATAL_ERROR | \[arduino\] Board '{1}' not found in {2}.<br>Set arduino.board to an ID from the core boards.txt or to auto. |
| `SCY-E504` | FATAL_ERROR | \[arduino\] Cannot select a board for mcu '{1}'. Candidates: {2}.<br>Set arduino.board in stm32\_config.yml. |
| `SCY-E505` | FATAL_ERROR | \[arduino\] arduino.cmsis\_path: no CMSIS/Core/Include/cmsis\_version.h in {1}. |
| `SCY-E506` | FATAL_ERROR | \[arduino\] CMSIS not found. Searched: {1}.<br>Set arduino.cmsis\_path (a directory with CMSIS/Core/Include) or external. |
| `SCY-E507` | FATAL_ERROR | \[arduino\] arduino.cmsis\_target: target '{1}' is not defined in the project. |
| `SCY-E508` | FATAL_ERROR | \[arduino\] Target '{1}' already exists: the name equals the board ID. Rename the project target. |
| `SCY-E509` | FATAL_ERROR | \[arduino\] Unrecognized board database format: {1}. |
| `SCY-E510` | FATAL_ERROR | \[arduino\] Target '{1}' already exists: in the native mode this is an Arduino core target name. Rename the project target. |
| `SCY-W501` | WARNING | \[arduino\] arduino.mcu\_target is not set. CMakeLists.txt of libraries that depend on MCU\_TARGET may fail. |
| `SCY-W502` | WARNING | \[arduino\] Arduino core CMakeLists.txt not found: {1}<br>Set the correct path with arduino.core\_cmake\_dir in stm32\_config.yml. |
| `SCY-W503` | WARNING | \[arduino\] Library '{1}' not found in {2}.<br>Check the name in arduino.libraries and that CMakeLists.txt exists. |
| `SCY-W504` | WARNING | \[arduino\] Custom library not found: {1}. |
| `SCY-W505` | WARNING | \[arduino\] CMSIS from STM32Cube (CMSIS 5 instead of CMSIS 6 expected by the core): {1} |
| `SCY-W506` | WARNING | \[arduino\] {1} is not used in the native mode. |
| `SCY-I501` | STATUS | Arduino Core STM32: {1} |
| `SCY-I502` | STATUS | Arduino MCU\_TARGET: {1} |
| `SCY-I503` | STATUS | Arduino::Definitions created. |
| `SCY-I504` | STATUS | Arduino USE\_CORE\_MAIN: {1} |
| `SCY-I505` | STATUS | Adding Arduino Core: {1} |
| `SCY-I506` | STATUS | Adding Arduino library: {1} |
| `SCY-I507` | STATUS | Adding custom library: {1} |
| `SCY-I508` | STATUS | Arduino integration: {1} |
| `SCY-I509` | STATUS | Arduino board: {1} (arduino.board: {2}) |
| `SCY-I510` | STATUS | Arduino::Platform not created: mcu is not set. |
| `SCY-I511` | STATUS | Arduino::Platform not created: no board for mcu '{1}' (candidates: {2}). Set arduino.board. |
| `SCY-I512` | STATUS | Arduino::Platform not created: CMSIS not found (searched: {1}). Set arduino.cmsis\_path. |
| `SCY-I513` | STATUS | Arduino::Platform created: {1}. |
| `SCY-I514` | STATUS | CMSIS for Arduino: {1} ({2}) |
| `SCY-I515` | STATUS | CMSIS for Arduino comes from the project target {1} (arduino.cmsis\_path: external). |
| `SCY-I516` | STATUS | CMSIS for Arduino is provided by the project (arduino.cmsis\_path: external). |
| `SCY-I517` | STATUS | Arduino::Platform not created: no board database {1}. |
| `SCY-I518` | STATUS | CMSIS from STM32Cube (CMSIS 5 instead of CMSIS 6 expected by the core): {1} |
| `SCY-I519` | STATUS | Arduino main(): from the core (cores/arduino/main.cpp). |
| `SCY-I520` | STATUS | Arduino main(): from the project; the core main.cpp is excluded, --undefined=\_write is added. The project main() calls init() and initVariant(). |
| `SCY-I521` | STATUS | Board variant linker script: {1}. heap\_size and stack\_size do not apply; use a .ld.in template or linker\_script. |

## 6xx — Linker script

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E601` | FATAL_ERROR | The Arduino backend cannot generate a linker script without a local template. Add a template or set a ready linker script. |
| `SCY-E602` | FATAL_ERROR | The specified linker script is not found: '{1}'<br>Search directories: {2} |
| `SCY-W601` | WARNING | The memory sizes set ({1}) are not applied: stm32-cmake generates the linker script with its own sizes, heap {2} and stack {3} bytes. Add a {4} template (to the project root or linker\_script\_dir) or set the sizes in an explicit linker\_script. |
| `SCY-W602` | WARNING | The memory sizes set ({1}) are not applied: the explicit linker script '{2}' sets the sizes. Change them in the script or use an .ld.in template (linker\_script: auto). |
| `SCY-W603` | WARNING | Startup {1} sets the stack limit (MSPLIM) from the \_sstack symbol, but linker script {2} does not define it: linking will fail with 'undefined reference to \_sstack'. Add the line '\_sstack = \_estack - \_Min\_Stack\_Size;' to the .ld.in template or the explicit script, or add your own startup without MSPLIM through sources. |
| `SCY-W604` | WARNING | Startup {1} sets the stack limit (MSPLIM) from the \_sstack symbol, but the stm32-cmake linker script does not define it: linking will fail with 'undefined reference to \_sstack'. Add the line '\_sstack = \_estack - \_Min\_Stack\_Size;' to an .ld.in template or an explicit script, or add your own startup without MSPLIM through sources. |
| `SCY-I601` | STATUS | Linker script search directory: {1} |
| `SCY-I602` | STATUS | Generating the linker script from a template... |
| `SCY-I603` | STATUS | Local template found: {1} |
| `SCY-I604` | STATUS | Using READONLY in linker script (GCC &gt;= 11.0) |
| `SCY-I605` | STATUS | Not using READONLY in linker script (GCC &lt; 11.0) |
| `SCY-I606` | STATUS | No local template found. The standard linker script is used. |
| `SCY-I607` | STATUS | Adding linker script: {1} |
| `SCY-I608` | STATUS | Adding the built-in linker script: {1} |
| `SCY-I609` | STATUS | Using the custom linker script: {1} |

## 7xx — Artifacts and CRC

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E701` | FATAL_ERROR | crc\_enable: stm32-cmake generates the linker script and it has no '{1}' section (crc\_section\_name). Use an STM32&lt;MCU&gt;\_FLASH.ld.in template (linker\_script: auto) or an explicit linker\_script with a '{1}' section, or crc\_enable: false. |
| `SCY-E702` | FATAL_ERROR | '{1}' is not a 32-bit little-endian ELF file |
| `SCY-E703` | FATAL_ERROR | No loadable sections inside FLASH 0x{1}+0x{2} in '{3}' |
| `SCY-E704` | FATAL_ERROR | Invalid number '{1}' in {2} |
| `SCY-E705` | FATAL_ERROR | Invalid --flash value '{1}', expected &lt;origin&gt;:&lt;length&gt; |
| `SCY-E706` | FATAL_ERROR | CRC image is larger than the FLASH limit: {1} &gt; {2} bytes. Check 'flash\_size' and the FLASH region of the linker script. |
| `SCY-E707` | FATAL_ERROR | Pass &lt;output.bin&gt; for the CRC or --image for the FLASH image |
| `SCY-E708` | FATAL_ERROR | Build failed: CRC was not calculated. |
| `SCY-E709` | FATAL_ERROR | Input file '{1}' not found. |
| `SCY-E710` | FATAL_ERROR | Usage: stm32\_crc.py &lt;input.bin&gt; &lt;output.bin&gt; \[limit\] \| --elf &lt;input.elf&gt; --flash &lt;origin&gt;:&lt;length&gt; --exclude &lt;section&gt; &lt;output.bin&gt; \[limit\] |
| `SCY-E711` | FATAL_ERROR | I/O error: {1} |
| `SCY-E712` | FATAL_ERROR | crc\_method: unknown value '{1}'. Expected auto or none (alias of auto). |
| `SCY-E713` | FATAL_ERROR | \[STM32 CRC32\] Injection into '{1}' failed: objcopy exited with code {2}. {3} |
| `SCY-E714` | FATAL_ERROR | \[STM32 CRC32\] Cannot run objcopy '{1}' for section '{2}': {3} |
| `SCY-E715` | FATAL_ERROR | \[STM32 CRC32\] --objcopy requires a CRC output file and exactly one --exclude section. |
| `SCY-W701` | WARNING | bin: could not find the FLASH region of the linker script or Python3; BIN is created by objcopy -O binary and may be large if the ELF has sections outside Flash. |
| `SCY-W702` | WARNING | CRC calculation is disabled. Could not determine the FLASH size from {1}. Set 'flash\_size' in stm32\_config.yml. |
| `SCY-W703` | WARNING | crc\_enable: section '{1}' (crc\_section\_name) is not found in script {2}. The post-build CRC step will fail. |
| `SCY-W704` | WARNING | CRC calculation is disabled. Could not determine the FLASH region (ORIGIN, LENGTH) in script {1}. |
| `SCY-W705` | WARNING | Python3 interpreter not found. CRC calculation is disabled. |
| `SCY-W706` | WARNING | objcopy not found. CRC calculation is disabled. |
| `SCY-W707` | WARNING | CRC script not found: {1}. CRC calculation is disabled. |
| `SCY-I701` | STATUS | Setting up CRC32 injection into the firmware... |
| `SCY-I702` | STATUS | \[STM32 CRC32\] Section: '{1}' |
| `SCY-I703` | STATUS | \[STM32 CRC32\] Algorithm: {1} |
| `SCY-I704` | STATUS | Script FLASH region: ORIGIN {1}, LENGTH {2} bytes |
| `SCY-I705` | STATUS | Max Flash Size: {1} bytes ({2}) |
| `SCY-I706` | STATUS | The build runs WITHOUT adding a checksum. |
| `SCY-I707` | STATUS | {1} Skipped {2}: load address 0x{3} ({4} bytes) is outside FLASH |
| `SCY-I708` | STATUS | {1} Written {2}: {3} bytes from 0x{4} |
| `SCY-I709` | STATUS | \[STM32 CRC32\] Calculated: 0x{1} (Size: {2} bytes from 0x{3}) |
| `SCY-I710` | STATUS | \[STM32 CRC32\] Calculated: 0x{1} (Size: {2} bytes) |
| `SCY-I711` | STATUS | \[STM32 CRC32\] Method: {1} (CRC calculation and placement) |
| `SCY-I712` | STATUS | \[STM32 CRC32\] Place the 4-byte section at the end of the FLASH image, aligned to 4 bytes, in the user linker script. Configure does not verify the final section position. |
| `SCY-I713` | STATUS | \[STM32 CRC32\] Injecting checksum into '{1}': |
| `SCY-I714` | STATUS | \[STM32 CRC32\] Injection into '{1}' successful! |
| `SCY-I715` | STATUS | \[STM32 CRC32\] objcopy: {1} |

## 8xx — Diagnostics

| Code | Level | Text |
| --- | --- | --- |
| `SCY-E801` | FATAL_ERROR | HAL configuration file '{1}' is not found in any directory listed in 'include\_directories'. The HAL library cannot compile without it. Make sure its path (for example, 'Core/Inc') is in 'include\_directories' in {2}. |
| `SCY-W801` | WARNING | No RAM section (xrw/rw) found in script {1}. The size check is skipped. |
| `SCY-W802` | WARNING | 'cppcheck\_enable' is set, but the tool is not found! |
| `SCY-I801` | STATUS | --- Debug information for the final target '{1}' --- |
| `SCY-I802` | STATUS | Compile options (COMPILE\_OPTIONS):<br>    {1} |
| `SCY-I803` | STATUS | Compile definitions (COMPILE\_DEFINITIONS):<br>    {1} |
| `SCY-I804` | STATUS | #include directories (INCLUDE\_DIRECTORIES):<br>    {1} |
| `SCY-I805` | STATUS | Link options (LINK\_OPTIONS):<br>    {1} |
| `SCY-I806` | STATUS | Link libraries (LINK\_LIBRARIES):<br>    {1} |
| `SCY-I807` | STATUS | <br>--- Debug information for the inherited target '{1}' --- |
| `SCY-I808` | STATUS | INTERFACE compile options:<br>    {1} |
| `SCY-I809` | STATUS | INTERFACE compile definitions:<br>    {1} |
| `SCY-I810` | STATUS | INTERFACE link options:<br>    {1} |
| `SCY-I811` | STATUS | --------------------------------------------------------------------------------- |
| `SCY-I812` | STATUS | HAL configuration file found: {1} |
| `SCY-I813` | STATUS | The linker script RAM size check is skipped (not supported by the Arduino backend). |
| `SCY-I814` | STATUS | Linker script RAM check: not checked (stm32-cmake generates the script). |
| `SCY-I815` | STATUS | Checking the linker script... |
| `SCY-I816` | STATUS | RAM sections in the script: {1} = {2} bytes |
| `SCY-I817` | STATUS | stm32-cmake RAM : {1} = {2} bytes |
| `SCY-I818` | STATUS | Script RAM total: {1} bytes ({2}K) |
| `SCY-I819` | STATUS | Ratio           : {1}K {2} {3}K |
| `SCY-I820` | STATUS | Cppcheck found: {1} |
| `SCY-I821` | STATUS | Cppcheck: paths containing '{1}' are ignored |
| `SCY-I822` | STATUS | Static analysis (Cppcheck) is enabled |
