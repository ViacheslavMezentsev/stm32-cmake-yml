# STM32 CMake YML Framework

[![Configure tests](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions/workflows/configure.yml/badge.svg?branch=main)](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions/workflows/configure.yml?query=branch%3Amain)
[![Documentation reference](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions/workflows/documentation.yml/badge.svg?branch=main)](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions/workflows/documentation.yml?query=branch%3Amain)

[Документация RU](docs/ru/index.md) · [Documentation EN](docs/en/index.md) · [Roadmap](TODO.md)

**stm32-cmake-yml** — декларативная конфигурация STM32-проектов через
`stm32_config.yml` поверх [stm32-cmake](https://github.com/ObKo/stm32-cmake).
Поддерживает настройки из CubeMX IOC, именованные профили, ручную конфигурацию
и Arduino Core STM32 через пользовательские CMake-обёртки.

Declarative STM32 project configuration through YAML, with CubeMX IOC input,
profiles, manual configuration and an Arduino backend using consumer CMake wrappers.

## Проверки / Checks

<!-- configure-counts -->
**100 scenarios × 6 tool pairs = 600 configure executions**
<!-- /configure-counts -->

Объём набора этой версии: три xPack GCC × два CMake, включая CMake 3.19.8.
Число проверяется по manifest в CI; это не счётчик успешных запусков.
Бейджи показывают состояние workflow на `main`. Проверяется Configure/Generate,
а не компиляция, линковка или исполнение прошивки.

The count describes this checkout's suite, not passed tests. Badges show workflow
status on `main`. Scope and local commands: [RU](docs/ru/testing.md) / [EN](docs/en/testing.md).

## Начало работы

Нужны CMake 3.19+, Arm GCC и Mike Farah yq; Python используется для CRC.
Подключение, toolchain и минимальный CMakeLists: [RU](docs/ru/getting-started.md) / [EN](docs/en/getting-started.md).

| Задача / Task | Русский | English |
| --- | --- | --- |
| IOC, профили, Arduino / Usage scenarios | [Сценарии](docs/ru/scenarios.md) | [Scenarios](docs/en/scenarios.md) |
| Значения и приоритеты / Option contracts | [Reference 0.9.2](docs/ru/reference/0.9.2/index.md) | [Reference 0.9.2](docs/en/reference/0.9.2/index.md) |
| Ограничения и обходы / Known issues | [Errata](docs/ru/errata/index.md) | [Errata](docs/en/errata/index.md) |
| VS Code, кэш, bare metal / Development | [Режимы разработки](docs/ru/development.md) | [Development](docs/en/development.md) |
| Устройство и навыки / Structure and skills | [Репозиторий](docs/ru/repository.md) | [Repository](docs/en/repository.md) |

[Подробное руководство](docs/user_manual.md) · [Примеры / Examples](https://github.com/ViacheslavMezentsev/demo-stm32-cmake)
· [Changelog](CHANGELOG.md) · [MIT License](LICENSE)
