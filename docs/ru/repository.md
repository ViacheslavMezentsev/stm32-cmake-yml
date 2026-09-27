# Устройство репозитория

[Документация](index.md) · [English](../en/repository.md)

## Структура репозитория

```text
stm32-cmake-yml/
├── stm32_yml.cmake                  # Точка входа, подключается через include()
├── cmake/
│   ├── stm32_yml_config.cmake       # Парсинг YAML и .ioc, подготовка переменных
│   ├── stm32_yml_profiles.cmake     # Профили сборки и cmake-overrides
│   ├── stm32_yml_arduino.cmake      # Arduino Core STM32 backend
│   ├── stm32_yml_frameworks.cmake   # HAL, CMSIS, FreeRTOS через stm32-cmake
│   ├── stm32_yml_sources.cmake      # Подключение исходников и include-директорий
│   ├── stm32_yml_linker.cmake       # Генерация и подключение скрипта компоновщика
│   ├── stm32_yml_postbuild.cmake    # Постсборочные команды: CRC, артефакты
│   ├── stm32_yml_diagnostics.cmake  # Проверка RAM, вывод свойств цели
│   ├── stm32_yml_code_quality.cmake # Статический анализ (Cppcheck)
│   └── stm32_yml_utils.cmake        # Утилиты: парсер YAML/JSON, нормализация флагов
├── scripts/
│   └── stm32_crc.py                 # Расчёт и внедрение CRC32 в ELF
├── docs/
│   └── user_manual.md               # Полное руководство пользователя
├── skills/
│   ├── stm32-config-manager/        # Навык AI: управление stm32_config.yml
│   ├── stm32-simple-sources/        # Навык AI: подключение исходников из CubeMX
│   ├── stm32-module-creator/        # Навык AI: создание библиотечных модулей
│   └── stm32-build-helper/          # Навык AI: диагностика ошибок сборки
├── tests/                           # Configure-сценарии, тестовые прошивки, модели Renode
├── ci/                              # Docker-образы, runner'ы проверок, lock-файл версий
├── tools/qemu/                      # Архив QEMU для CI и скрипт его сборки
├── .github/workflows/               # CI GitHub Actions
├── AGENTS.md                        # Порядок работы для ИИ-агентов
├── TODO.md                          # Дорожная карта и статус этапов
├── README.md / README.en.md
├── CHANGELOG.md / CHANGELOG.en.md   # История изменений RU / EN
└── LICENSE
```

`tests/` и `ci/` подробно — [уровни проверок и где их искать](testing.md#уровни-проверок-и-где-их-искать).
`docs/ru` и `docs/en` содержат навигацию, reference и errata; `docs/reference-index.json`
связывает опции с тестами. [Правила сопровождения](maintenance.md).

## Благодарности

Архитектура модулей CMake и рефакторинг кодовой базы выполнены совместно
с AI-ассистентами (Google Gemini, Anthropic Claude).

## Навыки агентов

- [stm32-config-manager](../../skills/stm32-config-manager/SKILL.md): YAML, reference и errata.
- [stm32-simple-sources](../../skills/stm32-simple-sources/SKILL.md): обновлён по наблюдаемым командам компиляции; [руководство](simple-sources.md).
- [stm32-module-creator](../../skills/stm32-module-creator/SKILL.md): обновлён по проверкам зависимостей и передачи флагов; [руководство](modules.md).
- [stm32-build-helper](../../skills/stm32-build-helper/SKILL.md): диагностика по стадиям и проверенные Configure-сообщения; [руководство](troubleshooting.md).

Передавайте SKILL.md ассистенту способом, который поддерживает ваш инструмент.
Инструкция сама по себе не гарантирует совместимость инструмента или правильность
кода. Все четыре навыка согласованы со справочником в рамках описанного покрытия.
Обновлять их будем постепенно по подтверждённому поведению: Configure-тесты не
доказывают совместимость ABI, успешную линковку или отсутствие HardFault.
[Дорожная карта](../../TODO.md).
