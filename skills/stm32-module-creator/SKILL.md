---
name: stm32-module-creator
description: Создание и подключение отдельных CMake-библиотек в stm32-cmake-yml с явными зависимостями и проверкой сгенерированных настроек. Используйте для переиспользуемых модулей; для добавления файлов в основную цель подходит stm32-simple-sources.
license: MIT
metadata:
  version: "0.2"
  framework: stm32-cmake-yml
---

# Библиотечные модули / Library modules

Ориентир: проверенный контракт stm32-cmake-yml 0.9.2, CMake 3.19+.
Проверьте checkout потребителя и применимые errata; более ранняя совместимость
не устанавливается одной строкой версии старого навыка.

Прочитайте [руководство RU](../../docs/ru/modules.md) или
[EN](../../docs/en/modules.md), а также карточки
[sources/link_libraries](../../docs/ru/reference/0.9.2/sources.md).
Если навык установлен отдельно, ищите docs/ в checkout фреймворка потребителя.
При отсутствии подходящего справочника исследуйте подключённую реализацию.

## Создание и подключение — два шага

Каталог в YAML sources вызывает add_subdirectory. Его CMakeLists может создать
STATIC-библиотеку, но приложение должно явно связаться с её целью через
link_libraries либо target_link_libraries. Имя цели должно быть уникальным;
совпадение с именем папки не является требованием CMake или фреймворка.
Не добавляйте один каталог одновременно несколькими путями подключения.

```yaml
sources: [main.c, Modules/Sensor]
link_libraries: [App::Sensor]
```

```cmake
# Modules/Sensor/CMakeLists.txt; paths must exist.
add_library(sensor STATIC Src/sensor.c)
add_library(App::Sensor ALIAS sensor)
target_include_directories(sensor PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/Inc")
target_compile_definitions(sensor PRIVATE SENSOR_INTERNAL=1)
```

Этот фрагмент задаёт исходники и публичные заголовки. CPU/ABI-флаги, зависимости
и общие настройки проекта подключите явно; это не самодостаточный STM32 toolchain.
Не копируйте имена HAL/CMSIS/FreeRTOS targets из другого проекта без проверки.

## Передача настроек

- YAML compile_options/definitions относятся к основной цели PRIVATE. Линковка
  приложения с библиотекой не передаёт эти настройки в обратном направлении.
- Для настроек, общих приложению и библиотекам, используйте выбранную проектом
  INTERFACE-цель и свяжите с ней нужные цели. Не снимайте вслепую все свойства
  executable и не копируйте их как глобальные compiler flags.
- PUBLIC заголовки/definitions библиотеки доступны ей и её потребителям;
  PRIVATE compile-настройки остаются у самой библиотеки. Это не означает,
  что PRIVATE зависимость статической библиотеки исчезает из финальной линковки.
- CMAKE_C_STANDARD/CMAKE_CXX_STANDARD инициализируют свойства при создании цели;
  они не образуют постоянное наследование от executable. Допустимы согласованные
  target-specific стандарты. Языковые generator expressions проверяйте отдельно.
- Согласуйте CPU, Thumb, FPU/float ABI и runtime requirements для всех связанных
  объектов. Наличие общего INTERFACE не доказывает ABI-совместимость.

## Зависимости и порядок

В обычном backend sources обрабатывается до setup_frameworks. Импортированные
цели могут ещё отсутствовать во время чтения CMakeLists каталога. Проверяйте,
что они создаются до Generate, и не обращайтесь к их свойствам раньше создания.
Используйте зависимости фактического пакета, MCU/core и выбранных компонентов.
Не подключайте полный набор HAL/FreeRTOS к модулю, которому они не нужны.

Проверьте INTERFACE_SOURCES у CMSIS/startup targets прежде чем использовать их
для каждой библиотеки: добавление файлов старта не равно передаче CPU flags.
В bare metal необходимые настройки и startup обеспечивает потребитель.
Arduino wrappers и custom_libraries имеют отдельную семантику; не переносите
их правила на обычный backend. Для custom_libraries сверяйтесь с reference.

## Проверка и пределы

Выполните Configure/Generate с toolchain проекта и compile_commands.json.
Проверьте владельца C/C++-исходников, общие и частные definitions, include-пути,
языковые флаги и граф линковки. Отсутствие ::-цели должно диагностироваться
Generate; простое имя может трактоваться как внешняя библиотека и отложить
ошибку до Link, поэтому ALIAS полезен для проверки внутренних зависимостей.

В [manifest](../../tests/cases.json): configure.module-explicit-link,
configure.module-not-auto-linked, configure.module-missing-target.
Они проверяют граф и команды, но не создают архивы/ELF, не проверяют разрешение
символов, порядок извлечения объектов, ABI или запуск. Не выполняйте незапрошенную
полную сборку ради задачи конфигурации; ожидаемое поведение при неоднозначности
уточняйте у автора.

## English routing

Use the English guide above. Creating a library and linking the application to it
are distinct steps. Executable PRIVATE YAML flags do not propagate backwards to
libraries. Use explicit dependency targets and shared INTERFACE settings; verify
per-language generated commands and target ownership. Preserve consumer toolchain
choices and distinguish Configure evidence from link/runtime or ABI guarantees.
