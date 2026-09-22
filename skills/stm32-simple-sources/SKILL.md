---
name: stm32-simple-sources
description: Подключение существующих C/C++/ASM-файлов и папок к основной цели stm32-cmake-yml без отдельной библиотеки. Используйте для CubeMX Core, пользовательских исходников и диагностики их путей или флагов.
license: MIT
metadata:
  version: "0.2"
  use_case: CubeMX code, system files, simple source collections
---

# Исходники основной цели / Main-target sources

Совместимость: stm32-cmake-yml 0.9.2, CMake 3.19+. Проверяйте фактически
подключённый checkout и его reference; строка версии не доказывает наличие фиксов.

## Выбрать способ подключения

Прочитайте [руководство RU](../../docs/ru/simple-sources.md) или
[EN](../../docs/en/simple-sources.md) и карточку
[sources](../../docs/ru/reference/0.9.2/sources.md#sources).
Для отдельно установленного навыка разрешайте пути docs/ относительно checkout
фреймворка потребителя. Если документов нет или версия другая, исследуйте код
этого checkout; не выдавайте неподтверждённые рекомендации за контракт.

- Отдельный обычный файл можно перечислить прямо в YAML `sources`.
- Каталог в `sources` подключается через add_subdirectory и требует своего
  CMakeLists.txt. Для файлов основной цели используйте target_sources, без
  создания отдельной библиотеки или повторного вызова project().
- При необходимости самостоятельной библиотеки этот способ не заменяет
  управление её зависимостями; рассматривайте отдельную задачу модуля.

## Сохранить семантику CMake

Потребитель вызывает prepare → project → setup. Framework создаёт исполняемую
цель и обрабатывает каталог внутри setup. В обычной интеграции имя цели —
`${PROJECT_NAME}`; проверьте его, если структура проекта отличается.

```cmake
# Core/CMakeLists.txt; files must exist in this directory.
target_sources(${PROJECT_NAME} PRIVATE Src/app.c Src/helper.cpp)
target_include_directories(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Inc")
```

Пути target_sources относительны текущей source-папке. PRIVATE include-путь
доступен всем компилируемым исходникам цели, включая файлы из других папок;
он не экспортируется потребителям цели. Это не изоляция папки.

Общие настройки цели применяются совместно, но C, C++ и ASM могут иметь разные
флаги, стандарты, generator expressions и свойства исходников. Не обещайте
одинаковые команды или автоматическую ABI-совместимость. Языки должны быть
включены в проекте; для ассемблера нужен ASM.

## Startup и системные файлы

Различайте прямые YAML-пути и файлы, добавленные внутри дочернего CMakeLists:
перехват подходящих startup/system имён в stm32_yml_setup_sources выполняется
для элементов YAML, а не рекурсивным просмотром target_sources. При CMSIS не
добавляйте второй startup без проверки уже подключённых исходников. Учитывайте
backend и установленную версию stm32-cmake; имена файлов влияют на перехват.

Без CMSIS программист обеспечивает reset, векторы, инициализацию памяти, linker
script и CPU/ABI-настройки. Для Arduino проверьте Core и CMake-обёртки.
См. [границы Configure RU](../../docs/ru/development.md) /
[EN](../../docs/en/development.md). Не превращайте задачу подключения исходников
в незапрошенную генерацию или запуск прошивки.

## Проверить результат

Настройте проект с его toolchain и CMAKE_EXPORT_COMPILE_COMMANDS=ON. Проверьте
список файлов и compile_commands.json: принадлежность цели, базу путей, include,
общие и языковые флаги. Успешный Configure не доказывает, что заголовки разрешаются
компилятором, прошивка линкуется или запускается.

Для репозитория доступны configure.source-directory-target,
configure.source-missing-warning и configure.source-directory-requires-cmake
в [manifest](../../tests/cases.json). Они проверяют конкретные сценарии, не весь
CubeMX и не startup. Рабочий процесс с чистым кэшем допустим; повторный Configure
проверяйте отдельно, если менялись профили/overrides.

Отсутствующий путь сейчас предупреждает и пропускается; каталог без CMakeLists
завершает Configure ошибкой. Не скрывайте пропущенный нужный исходник за зелёным
Configure. При изменении состава явного списка достаточно перенастройки;
удалять build-папку как обязательный шаг не нужно.

## English routing

Use the English guide linked above. Add ordinary files directly or use a source
directory's CMakeLists to extend the existing target. PRIVATE is target-wide,
not directory-local; language-specific flags still differ. Inspect generated
commands and source ownership. Distinguish YAML startup interception from nested
target_sources and never infer ABI, link or runtime success from Configure alone.
