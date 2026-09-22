# Сценарии применения

[Документация](index.md) · [English](../en/scenarios.md)

Это фрагменты конфигурации для адаптации к своему проекту, не готовые прошивки.
Пути, зависимости и исходники должны существовать. Точные ограничения — в
[reference](reference/0.9.2/index.md) и [errata](errata/index.md).

### Стандартный проект STM32CubeMX

IOC заполняет поддерживаемые поля; исходники и недостающие значения задайте явно.
Разбор IOC не создаёт стартовый код и не настраивает тактирование MCU.

```yaml
stm32_cmake_yml_version: "0.9.2"
ioc_file: "my_project.ioc"
build_artifacts: [ bin, hex, map ]
crc_enable: true
```

### Ручная конфигурация без CubeMX

Для legacy-проектов или нестандартных конфигураций все параметры задаются явно.

```yaml
stm32_cmake_yml_version: "0.9.2"
mcu: STM32F411CEU6
heap_size: 512
stack_size: 1K
sources: [ Core, User ]
hal_components: [ GPIO, UART, DMA, TIMEx ]
use_freertos: true
freertos_components: [ ARM_CM4F, "Heap::4" ]
```

### Поддержка двух ревизий платы (профили)

Один конфигурационный файл, два варианта настройки в отдельных build-папках. Профиль перекрывает только то,
что отличается между ревизиями.

```yaml
stm32_cmake_yml_version: "0.9.2"

# Общие настройки для всех ревизий.
hal_components: [ GPIO, UART, DMA, CRC ]
use_freertos: true
crc_enable: true

profiles:
  F411:
    mcu: STM32F411CEU6
    ioc_file: "project_F411.ioc"
    linker_script_dir: "F411"
    sources_append: [ "F411/Core" ]
    compile_definitions: [ STM32F4xx ]

  G474:
    mcu: STM32G474RETx
    ioc_file: "project_G474.ioc"
    linker_script_dir: "G474"
    sources_append: [ "G474/Core" ]
    compile_definitions: [ STM32G4xx ]
    hal_components_append: [ FDCAN ]
```

Configure (toolchain подключается проектом):

```bash
cmake -DSTM32_YML_PROFILE=F411 -B build/F411 -S .
cmake -DSTM32_YML_PROFILE=G474 -B build/G474 -S .
```

### Arduino Core STM32

Для проектов на базе Arduino Core STM32 с сохранением всех возможностей фреймворка:
профилей, генерации скрипта компоновщика, расчёта CRC, артефактов и нормализации флагов.

```yaml
stm32_cmake_yml_version: "0.9.2"
toolchain_backend: arduino
mcu: STM32G474RET6  # Требуется для автоматической генерации скрипта компоновщика и CRC.

arduino:
  core_path: "modules/Arduino_Core_STM32"
  core_cmake_dir: "Arduino/Core"
  mcu_target: "G474"
  use_core_main: false

# Подключение модулей через локальные CMake-обертки.
custom_libraries:
  - "Arduino/libraries/SrcWrapper"
  - "Arduino/libraries/Wire"
  - "UserApp"

# Линковка логических модулей и системных библиотек.
link_libraries:
  - UserApp
  - Arduino::SrcWrapper
  - Arduino::Core
  - STM32::Nano

linker_script: auto
crc_enable: true

compile_definitions: [ STM32G474xx, USE_HAL_DRIVER ]
compile_options_cxx: [ fno-exceptions, fno-rtti ]
```

### Точечные cmake-overrides для CI

Непустые скалярные overrides применяются поверх профиля. Пустое значение
игнорируется; пропуск `-D` не удаляет прежнюю запись кэша.

```bash
cmake -DSTM32_YML_PROFILE=G474 \
      -DSTM32_YML_OVERRIDE_heap_size=8K \
      -DSTM32_YML_OVERRIDE_verbose_build=true
```


Bare metal и работа с кэшем: [режимы разработки](development.md).
