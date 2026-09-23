# Отдельные библиотечные модули

[Документация](index.md) · [English](../en/modules.md)

В отличие от [исходников основной цели](simple-sources.md), STATIC-библиотека
имеет собственные свойства компиляции. Создание её цели не связывает её с приложением.

## Минимальное подключение

```yaml
sources: [main.c, Modules/Sensor]
link_libraries: [App::Sensor]
```

```cmake
# Modules/Sensor/CMakeLists.txt
add_library(sensor STATIC Src/sensor.c)
add_library(App::Sensor ALIAS sensor)
target_include_directories(sensor PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/Inc")
target_compile_definitions(sensor PRIVATE SENSOR_INTERNAL=1)
```

Файлы должны существовать. Каталог в sources вызывает add_subdirectory;
link_libraries создаёт связь основной цели с библиотекой. Имя цели не обязано
совпадать с именем каталога. `custom_libraries` обычного backend задаёт пути к
готовым библиотечным файлам; не подменяйте им подключение CMake-каталога.
[Reference](reference/0.9.2/sources.md).

## Общие и частные настройки

YAML compile_options/compile_definitions устанавливаются PRIVATE на executable.
Они не переходят в библиотеку через связь executable → library. Для общих
настроек можно явно создать INTERFACE-цель:

```cmake
add_library(app_settings INTERFACE)
target_compile_definitions(app_settings INTERFACE APP_SETTING=1)
target_compile_options(app_settings INTERFACE
    "$<$<COMPILE_LANGUAGE:C>:-Wstrict-prototypes>"
    "$<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>")
target_link_libraries(sensor PRIVATE app_settings)
```

Добавьте app_settings также в YAML link_libraries, если эти настройки нужны
приложению. CPU/Thumb/FPU/float ABI должны быть согласованы с toolchain для всех
объектов; приведённые фрагменты не задают полный набор настроек MCU. Не переносите
MCU-специфичные значения между семействами вслепую.

PUBLIC include/definitions библиотеки передаются ей и потребителям; PRIVATE
compile-свойства остаются у библиотеки. При STATIC зависимость PRIVATE всё ещё
может потребоваться при финальной линковке. CMAKE_C_STANDARD/CMAKE_CXX_STANDARD
инициализируют свойства в момент создания цели, а не обеспечивают постоянное
наследование от executable. Target-specific настройки допустимы при согласованном контракте.

В обычном backend sources читается до setup_frameworks. Не запрашивайте свойства
CMSIS/HAL/FreeRTOS targets до их создания; убедитесь, что нужные зависимости
существуют к Generate. Используйте реальные имена и компоненты установленного
пакета. Проверьте INTERFACE_SOURCES перед передачей startup targets всем модулям.
Arduino имеет отдельную интеграцию; эти примеры не проверяют его wrappers.

## Что проверено

| Сценарий | Проверка Configure/Generate |
| --- | --- |
| `module-explicit-link` | YAML связывает приложение с ALIAS модуля; PUBLIC include/define передаются приложению, PRIVATE define — нет; общие настройки INTERFACE доходят до обеих целей; C/C++-флаги разделены. |
| `module-not-auto-linked` | Каталог создаёт библиотеку, но без link_libraries её PUBLIC define/include в приложении отсутствуют. YAML-флаги приложения не попадают в команды библиотеки. |
| `module-missing-target` | Неизвестная ::-цель завершает Generate ошибкой с нужной диагностикой. |

[Fixture](../../tests/fixtures/project/Module/CMakeLists.txt) · [Manifest](../../tests/cases.json)

Проверяются владельцы исходников, compile_commands.json, настройки стандартов
C11/C++17 в выбранном окружении и связь целей. Архивы и ELF не создаются. Разрешение
символов, корректность ABI, порядок извлечения объектов и запуск не доказаны.
Простое имя без :: может быть внешней библиотекой, поэтому отсутствие ошибки
Generate не доказывает её наличие. Новую поддержку MCU или startup эти тесты не заявляют.

Основание семантики зависимостей: [CMake 3.19 target_link_libraries](https://cmake.org/cmake/help/v3.19/command/target_link_libraries.html).
[Навык агента](../../skills/stm32-module-creator/SKILL.md).
