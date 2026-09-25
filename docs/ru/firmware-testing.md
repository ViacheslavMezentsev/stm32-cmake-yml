# Сборка прошивки и первые тесты QEMU

[Документация](index.md) · [English](../en/firmware-testing.md) · [Окружение](emulation.md)

Первый тест адаптирует [пример автора 02-semihosting для F1](../../tests/firmware/semihosting/README.md).
Он отделён от 115 configure-сценариев: **три сборки и три запуска QEMU**, одна пара
инструментов (xPack GCC 14.2.1-1.1 / CMake 3.28.3), CubeF1 1.8.7, QEMU 11.0.0.
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
docker run --rm --network none -e GCC_VERSION=14.2.1-1.1 -e CMAKE_VERSION=3.28.3 \
  -v "$PWD:/workspace:ro" -v "$PWD/build/firmware-smoke:/results" \
  stm32-yml-ci:local python3 /workspace/ci/build_firmware_smoke.py --output /results
docker run --rm --network none -v "$PWD:/workspace:ro" -v "$PWD/build/firmware-qemu:/results" \
  stm32-yml-emulation:local python3 /workspace/ci/run_qemu_smoke.py \
  --build /workspace/build/firmware-smoke --output /results
```

Готовые ELF можно запустить локальным QEMU в Windows:

```powershell
python ci/run_qemu_smoke.py --build build/firmware-smoke --output build/firmware-qemu-windows
python -m unittest discover -s tests -p test_firmware_runner.py
```

`--qemu` задаёт путь к программе. Сборки используют новые каталоги, манифест
сбрасывается в начале; неудачная сборка не подхватит старый успешный манифест.
[Workflow](../../.github/workflows/firmware.yml) собирает оба образа и сохраняет
артефакты/логи на 14 дней. Матрица компиляторов, runtime-проверки .data/.bss, CRC
и запуск Renode остаются следующими этапами. Запуск на netduino2 с F205 не
подтверждает поддержку периферии или модели тактирования F1.
