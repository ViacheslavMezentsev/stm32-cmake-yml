# Сборка прошивки и первые тесты QEMU

[Документация](index.md) · [English](../en/firmware-testing.md) · [Окружение](emulation.md)

Первый тест адаптирует [пример автора 02-semihosting для F1](../../tests/firmware/semihosting/README.md).
Он отделён от 115 configure-сценариев: **18 сборок и 18 запусков QEMU**:
три профиля × три версии xPack GCC × два CMake из
[lock-файла](../../ci/dependencies.lock.json), CubeF1 1.8.7, QEMU 11.0.0.
Локально проверен также Windows QEMU 11.1.0; CI использует закреплённый образ.

## Контракт

После сборки нужны непустые ELF/BIN/HEX/MAP/LSS. Проверка ELF контролирует ELF32 ARM,
согласованность Thumb reset-вектора и точки входа, выравнивание начального стека
в 20 КиБ RAM и размещение загружаемых сегментов в пределах FLASH/RAM F103C8
(64/20 КиБ), включая LMA .data. Вывод readelf сохраняется. Это не полная проверка
корректности любого linker script.

| Профиль | Ожидаемое выполнение |
| --- | --- |
| success | Вывод компилятора/цели/машины/ядра, TEST_RESULT=PASS, код 0 |
| failure | Тот же стартовый вывод, TEST_RESULT=FAIL, код 1 |
| hang | Стартовый вывод без маркера результата, таймаут через 5 секунд |

Обычные запуски ограничены 15 секундами. Зависание до вывода метаданных, авария,
отсутствующий маркер, неверный код выхода или противоречивые маркеры проваливают
набор. Намеренная ошибка и таймаут — успешные проверки тестового runner, а не
игнорирование сбоев. Сохраняются stdout/stderr, команды, коды и версия эмулятора.
GDB и GUI не запускаются. SYS_EXIT_EXTENDED получает блок причины/статуса;
stdio сбрасывается перед выходом. Версия GCC сравнивается с манифестом сборки.
Версии остальных библиотек пока выводятся для диагностики.

## Локальный запуск

Сначала собрать [образ компиляторов](testing.md) и [образ эмуляторов](emulation.md).
Команды ниже используют Linux shell и пути; в PowerShell нужны соответствующие
абсолютные пути bind mount. Исходники подключаются только для чтения.

```sh
mkdir -p build/firmware-smoke build/firmware-qemu
docker run --rm --network none \
  -v "$PWD:/workspace:ro" -v "$PWD/build/firmware-smoke:/results" \
  stm32-yml-ci:local python3 /workspace/ci/firmware_matrix.py build --output /results
docker run --rm --network none -v "$PWD:/workspace:ro" -v "$PWD/build/firmware-qemu:/results" \
  stm32-yml-emulation:local python3 /workspace/ci/firmware_matrix.py run \
  --build /workspace/build/firmware-smoke --output /results
```

Готовые ELF можно запустить локальным QEMU в Windows:

```powershell
python ci/firmware_matrix.py run --build build/firmware-smoke --output build/firmware-qemu-windows
python -m unittest discover -s tests -p "test_firmware*.py"
```

`--qemu` задаёт путь к программе. Сборки используют новые каталоги, манифест
сбрасывается в начале; неудачная сборка не подхватит старый успешный манифест.
[Workflow](../../.github/workflows/firmware.yml) собирает оба образа и сохраняет
артефакты/логи на 14 дней. Runtime-проверки .data/.bss, CRC
и запуск Renode остаются следующими этапами. Запуск на netduino2 с F205 не
подтверждает поддержку периферии или модели тактирования F1.

## Изоляция матрицы и совместимость

Матрица читается из общего lock-файла зависимостей, без дублирования версий в YAML.
Образы собираются один раз; пары инструментов запускаются последовательно с
отдельными каталогами сборки/логов. Для каждой пары проверяются фактические версии
GCC/CMake и все три профиля. Ошибка не останавливает сбор результатов остальных
пар, но любая неудачная пара даёт ненулевой результат матрицы. Выбор запусков
определяется текущим lock-файлом, а не случайно оставшимися манифестами. Сводный
отчёт — matrix-summary.json, отчёты пары — build-summary.json и qemu-summary.json.

Тестовый пример использует C11 и C++17. CMake 3.19 отвергает C_STANDARD=17 даже
при поддержке C17 компилятором: это значение появилось в CMake 3.21. C-файлам
примера C17 не требуется. Изменена совместимость тестового примера, а не фреймворк.
Для одной пары сохранены build_firmware_smoke.py/run_qemu_smoke.py; использовать
отдельный каталог результатов.
