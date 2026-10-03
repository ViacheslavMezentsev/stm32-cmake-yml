# Errata

[Документация](../index.md) → Errata · [English](../../en/errata/index.md)

Применимость: база `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Статусы проверены 2026-09-27 при подготовке выпуска 0.9.3. Записи сохраняются после исправления.

| ID | Отклонение | Статус |
| --- | --- | --- |
| [E001](E001.md) | Производные значения залипают в кэше | Исправлено в 0.9.3 ([PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6)) |
| [E002](E002.md) | list не читает внешний файл профилей | Исправлено в 0.9.3 ([PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6)) |
| [E003](E003.md) | Только целочисленные размеры | Закрыто: по замыслу автора |
| [E004](E004.md) | crc_algorithm не переключает алгоритм | Исправлено в 0.9.3 ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), `4cd3404`) |
| [E005](E005.md) | Имена профилей без `_` | Закрыто: по замыслу автора |
| [E006](E006.md) | Ошибка CRC может завершаться успехом и заглушкой | Исправлено в 0.9.3 ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), `4cd3404`) |
| [E007](E007.md) | Внешний FreeRTOS: несовпадение пространств целей | Исправлено в 0.9.3 ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), `3c6bfa3`, `2f742ff`) |
| [E008](E008.md) | Языковые настройки только из профиля не экспортируются | Исправлено в 0.9.3 ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), `d8708b4`) |

[Reference](../reference/0.9.2/index.md) · [Как сопровождать записи](../maintenance.md)

Дополнение для 0.10.0, проверено 02.10.2026.

| ID | Отклонение | Статус |
| --- | --- | --- |
| [E009](E009.md) | Кодировка Python-диагностики CRC/BIN | Исправлено в 0.10.1 |
| [E010](E010.md) | Абсолютный sources на другом диске | Открыто; исправление отложено |
