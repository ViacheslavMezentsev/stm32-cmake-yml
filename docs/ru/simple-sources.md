# Подключение исходников к основной цели

[Документация](index.md) · [English](../en/simple-sources.md)

Этот способ подходит для существующих исходников Core/User, которым не нужна
самостоятельная библиотека. Параметры YAML описаны в [reference](reference/0.9.2/sources.md).

## Отдельный файл или каталог

```yaml
sources: [main.c, Core]
```

Обычный файл добавляется к основной цели. Каталог обрабатывается через
add_subdirectory; создайте Core/CMakeLists.txt:

```cmake
target_sources(${PROJECT_NAME} PRIVATE Src/app.c Src/helper.cpp)
target_include_directories(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Inc")
```

Используйте существующие файлы. Для helper.cpp включите CXX в languages.
Пути здесь отсчитываются от Core, а в YAML — от исходной папки проекта.
Framework создаёт основную цель до обработки sources внутри setup; не нужно
повторно вызывать project() или добавлять каталог после завершения setup.

PRIVATE включает каталог заголовков для всех исходников цели, в том числе main.c
в корне, но не экспортирует его потребителям. Общие флаги цели применяются к
добавленным файлам; C/C++/ASM при этом могут иметь разные стандарты и флаги.
Одна цель не гарантирует ABI-совместимость.

## Startup и backend

Перехват имён startup/system для CMSIS работает на прямых элементах YAML sources.
Файлы, добавленные внутри Core/CMakeLists.txt, не проходят этот перебор повторно.
Проверьте состав цели и зависимости перед добавлением собственного startup,
чтобы не получить дублирование. Без CMSIS стартовое окружение и флаги задаёт
программист; Arduino использует Core и обёртки. См. [режимы разработки](development.md).

## Проверки и ограничения

| Тест | Наблюдаемый результат |
| --- | --- |
| `configure.source-directory-target` | Вложенные C/C++ и корневой C принадлежат основной цели; общий include доступен всем трём; языковые флаги не переносятся между C и C++. |
| `configure.source-missing-warning` | Отсутствующий файл вызывает предупреждение и не добавляется к существующим исходникам. |
| `configure.source-directory-requires-cmake` | Существующий каталог без CMakeLists.txt вызывает ошибку Configure с нужной причиной. |

[Manifest](../../tests/cases.json) · [Fixture](../../tests/fixtures/project/SourceGroup/CMakeLists.txt)

Проверяется Configure/Generate и compile_commands.json. Компиляция заголовков,
линковка, CMSIS startup и запуск не проверяются этими сценариями. Предупреждение
о пропущенном нужном исходнике нужно исправить, даже если Configure завершился.
Проверка файлов основной цели не заменяет проверки наследования настроек отдельной библиотеки.

Семантика CMake 3.19: [target_sources](https://cmake.org/cmake/help/v3.19/command/target_sources.html),
[target_include_directories](https://cmake.org/cmake/help/v3.19/command/target_include_directories.html).
[Навык для агента](../../skills/stm32-simple-sources/SKILL.md).
