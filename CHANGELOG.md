# Changelog

Все заметные изменения в этом проекте документируются в этом файле.
Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/).

---

## [Unreleased]

### Исправлено / Fixed

- При смене профиля в одной build-папке обновляются MCU и размеры heap/stack
  локального linker template; старые производные значения больше не остаются в
  CMakeCache. Для явных overrides используются `STM32_YML_OVERRIDE_mcu`,
  `STM32_YML_OVERRIDE_heap_size` и `STM32_YML_OVERRIDE_stack_size`.
  Switching profiles now refreshes derived MCU and local linker-template memory
  values. Direct `MCU`/`HEAP_SIZE`/`STACK_SIZE` cache overrides are superseded by
  the resolved configuration; use the `STM32_YML_OVERRIDE_*` inputs instead.
- `STM32_YML_PROFILE=list` читает `profiles_file` так же, как выбор профиля.
  Profile listing now reads the external profile file as profile selection does.
- Промежуточный образ CRC строится из секций ELF с адресом загрузки в регионе
  `FLASH` скрипта компоновщика, без `objcopy --gap-fill`: секция вне Flash
  (например, в резервной SRAM STM32H5) больше не раздувает образ до сотен МБ.
  Для обычных проектов образ и CRC не меняются. Ограничение CRC для H5 снято.
  The CRC image is built from ELF sections loaded into the linker-script `FLASH`
  region instead of `objcopy --gap-fill`; sections outside FLASH no longer inflate
  it. Images and CRC of ordinary projects are unchanged; the H5 limitation is gone.
- Сбой расчёта CRC завершает сборку ошибкой `[CRC ERROR]`; нулевая заглушка
  больше не записывается (E006). Со скриптом, который формирует stm32-cmake,
  `crc_enable: true` — ошибка Configure; отсутствие секции `crc_section_name`
  в шаблоне или явном скрипте — предупреждение. Неизвестный `crc_algorithm`
  вызывает предупреждение, применяется `STM32_HW_DEFAULT` (E004).
  **Совместимость:** сборки, которые раньше завершались успешно с заглушкой
  `0x00000000`, теперь завершаются ошибкой; проекты с CRC без шаблона `.ld.in`
  или явного скрипта должны добавить его либо отключить CRC.
  A CRC failure now fails the build with `[CRC ERROR]` instead of writing a zero
  stub (E006). `crc_enable: true` with the stm32-cmake-generated linker script is
  a Configure error; a template or explicit script without the CRC section warns.
  An unknown `crc_algorithm` warns and `STM32_HW_DEFAULT` is applied (E004).
  **Compatibility:** builds that used to pass with a zero stub now fail; CRC
  projects without a `.ld.in` template or explicit script must add one or disable CRC.
- Ключи, заданные только в профиле или через `STM32_YML_OVERRIDE_*`, применяются
  без объявления в корне YAML, в том числе `compile_options_c`/`_cxx`,
  `compile_definitions_c`/`_cxx` и собственные ключи проекта (E008).
  Keys set only in a profile or override are applied without a root declaration,
  including the C/C++-specific options and project-specific keys (E008).
- Из `profiles_file` читается только секция `profiles:`; остальные ключи файла
  больше не подменяют базовое значение для `_append`.
  Only the `profiles:` section of `profiles_file` is read; its other keys no longer
  replace the base value for `_append`.
- При заданном `profiles_file` встроенная секция `profiles:` по-прежнему не
  используется, но выводится предупреждение со списком её профилей.
  With `profiles_file` set, an inline `profiles:` section is still unused, and a
  warning now lists its profiles.
- Изменение YAML, IOC-файла или `profiles_file` перезапускает Configure при
  следующей сборке. Changing the YAML, IOC or profile file re-runs Configure on
  the next build.
- IOC без имени проекта, `HeapSize` или `StackSize` получает значения ручного
  режима `auto`, 512 и 1024 вместо пустых. An incomplete IOC gets `auto`, 512
  and 1024 instead of empty values.
- Предупреждение о версии называет `stm32_cmake_yml_version` рекомендуемым
  параметром; справка «Что нового в 0.9» удалена. Подсказка о `hal_conf.h`
  называет фактический файл конфигурации. The version warning calls the parameter
  recommended; the `hal_conf.h` hint names the actual configuration file.
- `heap_size`/`stack_size` проверяются при каждом Configure: допустимы целое
  число байт или целое число с `K`/`M` в верхнем регистре. Явно заданные размеры
  при скрипте stm32-cmake или явном `linker_script` вызывают предупреждение, что
  они не применяются. **Совместимость:** значения вроде `1k` или `0x200` при
  скрипте без шаблона раньше молча игнорировались, теперь это ошибка Configure.
  Sizes are validated on every Configure (integer bytes or integer with upper-case
  `K`/`M`), and explicit sizes warn when the stm32-cmake or explicit linker script
  ignores them. **Compatibility:** values such as `1k` or `0x200` used to be ignored
  silently without a template and are now a Configure error.
- Неизвестные значения `toolchain_backend`, `system_library`, `cmsis_rtos_api`,
  `freertos_version` и элементов `build_artifacts` вызывают предупреждение со
  списком известных значений; применяется поведение по умолчанию (для
  `freertos_version` — `external`, как фактически в 0.9.2). Пустые значения не
  проверяются. Unknown values of these keys and `build_artifacts` elements now warn
  with the known values; the default behaviour applies, `external` for
  `freertos_version` as in 0.9.2. Empty values are not checked.
- Ядро MCU определяется по списку stm32-cmake: у одноядерных MCU (все H7 —
  `M7`) выбирается автоматически, у двухъядерных `mcu_core` обязателен, значение
  вне списка — ошибка со списком ядер. Ядро применяется к обёртке CMSIS-RTOS и к
  размерам RAM/Flash. The MCU core follows stm32-cmake: selected automatically
  for single-core MCUs (every H7 gets `M7`), required for dual-core ones, and
  validated; it now also reaches the CMSIS-RTOS wrapper and RAM/Flash sizes.
- `freertos_version: external` работает: FreeRTOS ищется в `FREERTOS_PATH`
  (дерево Cube или FreeRTOS-Kernel), подключаются цели `FreeRTOS::<порт>` (E007).
  External FreeRTOS from `FREERTOS_PATH` now works (E007).
- Отсутствующие компоненты `hal_components` и `freertos_components`, а также
  отсутствующая обёртка CMSIS-RTOS — ошибка Configure с именем компонента вместо
  ошибки Generate. Missing HAL/FreeRTOS components and CMSIS-RTOS wrappers fail
  Configure with the component name instead of failing Generate.
- Таблица портов FreeRTOS по IOC дополнена C0, U0, H5, L5, U5, WL и ядрами H7/WL;
  для неизвестного семейства — предупреждение. The IOC FreeRTOS port table covers
  the remaining families and cores and warns for an unknown family.
- Проверка RAM скрипта компоновщика учитывает CCRAM и RAM_SHARE и ядро; для
  скрипта stm32-cmake выводится «не проверялось». The RAM check includes CCRAM,
  RAM_SHARE and the core, and reports the stm32-cmake script as not checked.

### Добавлено / Added

- `build_artifacts: [srec]` — файл Motorola S-record через
  `stm32_generate_srec_file`. The `srec` artifact generates a Motorola S-record file.

## [0.9.2] - 2026-09-19

### Исправлено

- **Нормализация флагов ломала опции с отдельным аргументом.** Токен, следующий за опцией вида `--param`, `-include`, `-isystem`, `-Xlinker`, получал ведущий дефис и превращался в несуществующий флаг: запись `"--param max-inline-insns-single=500"` разворачивалась в `--param -max-inline-insns-single=500`, и компилятор отвергал её. `stm32_yml_normalize_flags` теперь распознаёт такие опции и переносит их значение без изменений. Состояние сохраняется между элементами списка, поэтому флаг и его значение можно записывать как одной строкой, так и двумя отдельными.

- **Разрушенный поток управления в парсере `.ioc`.** Блок постобработки, выбирающий версию пакета между `FirmwarePackage` и `CustomerFirmwarePackage`, оказался вложен в ветку `ProjectManager.LibraryCopy` внутри цикла разбора строк. Помимо неверного места он читал переменные, записанные через `set(... PARENT_SCOPE)`, которые в текущей области не меняются. Накопление значений переведено на локальные переменные, постобработка и экспорт вынесены за цикл. Приоритет `CustomerFirmwarePackage` теперь работает так, как описано в комментарии.

- **Семантика `_append` не видела замену из того же профиля.** Цикл обработки `_append` читал базовое значение из локальной области, где замена, выполненная через `PARENT_SCOPE`, не отражалась. Если профиль задавал и `X`, и `X_append`, дополнение приклеивалось к списку из корня  yml вместо списка профиля.

- **`-DSTM32_YML_PROFILE=list` не находил профили без ключа `mcu`.** Поиск был привязан к регулярному выражению `^profiles_([^_]+)_mcu$`. Теперь профиль определяется по любому своему ключу, результат дедуплицируется.

- **Пустая метка источника FreeRTOS** в итоговой таблице параметров: переменная `_src_freertos_flag` нигде не вычислялась.

- **Небезопасное сравнение `project_name`.** Конструкция `if(${project_name} ...)` без кавычек ломала синтаксис CMake, если `.ioc` не содержал `ProjectManager.ProjectName`.

- **Суффикс `M` в эталонном размере RAM.** Диагностика обрабатывала только `K`, из-за чего `math(EXPR)` падал на значении вида `1M` (H7, F7).

- **Подключение каталога вне дерева проекта.** `add_subdirectory` вызывался без явной бинарной директории, что для пути вроде `../shared` приводило к ошибке конфигурации.

- **Коллизия бинарных директорий кастомных библиотек Arduino.** Имя формировалось из последнего сегмента пути, поэтому `Arduino/libraries/Cli` и `Components/Cli` давали одинаковый путь. Теперь используется весь относительный путь, из-за чего имена директорий объектных файлов изменились (первая сборка после обновления будет полной).

### Изменено

- **Очистка артефактов предыдущих патчей:** удалён неиспользуемый список `_STM32_YML_LIST_PARAMS`, устранён продублированный заголовок парсера `.ioc`, документация `stm32_yml_ensure_default_value` возвращена к своей функции, выровнены отступы `stm32_yml_setup_system_libraries`, убрано повторное вычисление эталонного размера RAM, удалён фрагмент ap-патча из руководства пользователя.

- **Защищено сравнение `system_library`** кавычками: параметр необязателен, и без них CMake сравнивал имя переменной со строкой.

---

## [0.9.1] - 2026-09-13

### Добавлено

- **Автоопределение размера FLASH (`flash_size: "auto"`):** Модуль Postbuild теперь умеет парсить скрипт компоновщика (`.ld`) для автоматического определения размера FLASH-памяти. Это вернуло поддержку внедрения аппаратного CRC32 для Arduino-бэкенда без необходимости явно задавать размер в конфигурации.
- **Глобальное применение системных библиотек:** Настройки `use_newlib_nano` и `system_library` вынесены в независимую функцию `stm32_yml_setup_system_libraries`. Теперь они корректно работают для всех бэкендов сборки, включая Arduino.

### Изменено

- **Нативный линкер для Arduino:** Логика подключения скрипта компоновщика для `arduino` бэкенда переведена на нативные механизмы CMake (`target_link_options` и свойство `LINK_DEPENDS`). Устранена жесткая зависимость от макроса `stm32_add_linker_script`.
- **Очистка логов конфигурации:** Вывод CMake при Arduino-бэкенде полностью очищен от информационного "мусора". Фреймворк больше не спамит сообщениями о поиске `ioc_file`, `use_cmsis`, `use_hal`, `use_freertos` и `mcu_core`.
- **Тихие логи CRC:** Параметры `crc_section_name` и `crc_algorithm` теперь инициализируются и отображаются в логе только если механизм `crc_enable` действительно включен.

### Исправлено

- **Проброс `use_core_main`:** Исправлена критическая ошибка, из-за которой параметр `arduino.use_core_main` из YAML не передавался в ядро Arduino. Теперь значение форсированно записывается в `CMakeCache.txt`.
- **Путь к скрипту `stm32_crc.py`:** Исправлена потерянная переменная пути. Теперь используется относительный путь `CMAKE_CURRENT_FUNCTION_LIST_DIR`, что гарантирует нахождение скрипта при любом расположении фреймворка.
- **Изоляция диагностики:** Отключен поиск файла `hal_conf.h` и вызов макроса проверки RAM (`stm32_get_memory_info`) при Arduino-бэкенде. Ранее это приводило к фатальной ошибке конфигурации из-за отсутствия макросов `stm32-cmake`.
- **Каскадные предупреждения CRC:** Проверки наличия Python и `objcopy` теперь обернуты в условие `if(CRC_POSSIBLE)`, устраняя ложные предупреждения в консоли при выключенном механизме CRC.

---

## [0.9.0] - 2026-07-30

### Добавлено

- **Профили сборки (`profiles:`):** Новая секция в `stm32_config.yml` для поддержки
  нескольких ревизий платы или MCU в одном проекте. Профиль активируется через
  `-DSTM32_YML_PROFILE=<name>` при вызове CMake. Параметры профиля перекрывают
  базовые значения из yml. Для списочных параметров поддерживаются две семантики:
  замена (ключ без суффикса) и дополнение (суффикс `_append`). Опциональный вынос
  профилей во внешний файл через `profiles_file:`.

- **Точечные cmake-overrides (`-DSTM32_YML_OVERRIDE_*`):** Любой скалярный параметр
  из yml можно перекрыть через переменную CMake CACHE без правки файла конфигурации.
  Применяются поверх профиля. Удобны для отладки и экспериментов в CI.

- **Arduino Core STM32 backend (`toolchain_backend: arduino`):** Новый параметр
  `toolchain_backend` переключает фреймворк между режимами `stm32-cmake` (по умолчанию)
  и `arduino`. При Arduino backend HAL/CMSIS через stm32-cmake не подключаются.
  Новая секция `arduino:` задаёт путь к Arduino Core STM32, список стандартных
  и кастомных библиотек, вариант платы и флаг `use_core_main`. Фреймворк автоматически
  создаёт INTERFACE-таргет `Arduino::Definitions` и вызывает `add_subdirectory`
  для всех подключаемых библиотек.

- **Параметр `linker_script_dir`:** Задаёт папку поиска шаблона `.ld.in` и явного
  скрипта `.ld`. Устанавливается на базовом уровне или внутри профиля. Позволяет
  хранить MCU-специфичные скрипты в отдельных папках (`F411/`, `G474/`) при
  использовании профилей. При отсутствии параметра поведение идентично предыдущей
  версии (поиск в корне проекта).

- **Новый модуль `cmake/stm32_yml_profiles.cmake`:** Реализует загрузку и применение
  профилей, обработку семантики `_append`, применение cmake-overrides, вывод списка
  доступных профилей (`-DSTM32_YML_PROFILE=list`).

- **Новый модуль `cmake/stm32_yml_arduino.cmake`:** Реализует настройку Arduino
  Core STM32 backend: проверку наличия `core_path`, создание `Arduino::Definitions`,
  подключение ядра и библиотек через `add_subdirectory`.

### Изменено

- **Порядок приоритетов конфигурации** уточнён и задокументирован:
  значения по умолчанию → `ioc_file` → базовый yml → профиль → cmake-overrides.

- **`toolchain_backend` инициализируется в начале `stm32_yml_setup_project()`**
  до вызова `stm32_get_chip_info` и `add_executable` — устранено дублирование
  вызовов `ensure_default_value`.

- **`stm32_get_chip_info` защищён условием** `if(NOT toolchain_backend STREQUAL "arduino")` —
  функция вызывается только при backend stm32-cmake, где доступен `stm32_gcc.cmake` toolchain.

- **Алгоритм поиска шаблона компоновщика** переработан: перебор папок из `_search_dirs`
  (сначала `linker_script_dir`, затем корень проекта) заменил три отдельных блока
  `if(NOT EXISTS ...)`. Та же логика применяется к явному скриптому в ветке `else`.

- **Сообщение о несовпадении версий** (`stm32_cmake_yml_version_check`) расширено:
  теперь перечисляет нововведения версии 0.9 и явно указывает на обратную совместимость.

- **Версия фреймворка:** `STM32_CMAKE_YML_VERSION` обновлена с `0.8` до `0.9`.

### Совместимость

Все изменения версии 0.9 обратно совместимы. Проект с `stm32_cmake_yml_version: "0.8"`
соберётся без ошибок и без правок в yml — будет выдано информационное предупреждение
с описанием нововведений.

---

## [0.8.0] - 2026-05-01

### Добавлено

- **Раздельные флаги компилятора для C и C++:** Новые параметры `compile_options_c`,
  `compile_options_cxx`, `compile_definitions_c`, `compile_definitions_cxx`. Передаются
  через генераторные выражения `$<COMPILE_LANGUAGE:C>` и `$<COMPILE_LANGUAGE:CXX>`.
  Общие ключи `compile_options` и `compile_definitions` сохраняют обратную совместимость.

- **Нормализация флагов компилятора (`stm32_yml_normalize_flags`):** Новая утилита
  в `stm32_yml_utils.cmake`. Разбивает строку с пробелами на отдельные флаги
  (`"-Wall -Wextra"` → два элемента), добавляет ведущий дефис если он отсутствует
  (`Wall` → `-Wall`). Генераторные выражения `$<...>` не затрагиваются. Для
  `compile_definitions` поддерживается режим `NO_AUTO_DASH` — CMake добавляет `-D`
  самостоятельно через `target_compile_definitions`.

- **Приоритет YAML над `.ioc`:** Параметры из `stm32_config.yml` явно перекрывают
  значения из `.ioc` файла CubeMX. Позволяет точечно переопределять отдельные
  параметры без изменения `.ioc`.

### Изменено

- **Алгоритм поиска шаблона компоновщика при `linker_script: auto`** расширен
  до трёх вариантов имени (для MCU `STM32H723VGT6`):
  1. `STM32H723VG_FLASH.ld.in` — точное совпадение.
  2. `STM32H723XG_FLASH.ld.in` — корпус заменён на X (стиль CubeMX).
  3. `STM32H723XX_FLASH.ld.in` — широкий фолбек.
  Имя выходного `.ld` файла теперь берётся из конкретного типа MCU (`H723VG`),
  а не из обобщённого `MCU_TYPE` (`H723xx`).

- **Извлечение типа MCU для поиска шаблона** исправлено: используется
  `string(SUBSTRING "${MCU}" 5 6 ...)` напрямую из полного имени MCU вместо
  результата `stm32_get_chip_info`, который возвращает обобщённый тип (`H723xx`).

- **Проверка RAM скрипта компоновщика** переработана: суммирует все RAM-секции
  с атрибутом `(xrw)` или `(rw)` из блока `MEMORY{}`, исключая секции с
  `ORIGIN = 0x00000000` (ITCMRAM). Корректно работает для H7 с несколькими
  RAM-регионами. Вместо `FATAL_ERROR` выводится информационное сравнение с
  данными от stm32-cmake.

---

## [0.7.1] - 2026-03-15

### Исправлено

- **`crc_enable: false` не отключал CRC-инъекцию.** Корневая причина: CMake
  `string(JSON GET)` возвращает булевы значения в верхнем регистре (`FALSE`/`TRUE`),
  тогда как нормализация сравнивала со строчными. Реализована трёхуровневая защита:
  нормализация при парсинге JSON (`stm32_yml_utils.cmake`), нормализация перед
  `PARENT_SCOPE` (`stm32_yml_config.cmake`), `string(TOUPPER)` в точке использования
  (`stm32_yml_postbuild.cmake`). Требует clean reconfigure (удаление `build/` или
  `CMakeCache.txt`) при переходе с версий где проблема проявлялась.

---

## [0.7.0] - 2026-02-20

### Добавлено

- **Диагностика CRC:** Расширенный вывод при внедрении CRC32 — адрес секции,
  размер данных, вычисленное значение.

- **Улучшения логирования:** Унифицированные префиксы сообщений `message(STATUS ...)`,
  разграничение информационных и предупреждающих сообщений.

- **Поддержка `CustomerFirmwarePackage`:** Возможность подключения кастомных пакетов
  прошивки наряду со стандартными STM32Cube.
