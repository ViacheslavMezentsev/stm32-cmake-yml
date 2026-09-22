---
name: stm32-config-manager
description: Настройка и диагностика stm32_config.yml для stm32-cmake-yml с учётом версии, reference, errata и конфигурационных тестов. Используйте при изменении MCU, профилей, драйверов, линковки, Arduino backend или опций сборки.
license: MIT
metadata:
  version: "0.3"
  framework: stm32-cmake-yml
---

# Менеджер конфигурации STM32 / STM32 configuration manager

Совместимость: справочник проверен для stm32-cmake-yml 0.9.2; CMake 3.19+,
Mike Farah yq. Для других версий проверяйте фактическую реализацию.

Настраивайте проект согласно намерению пользователя и контракту его версии
фреймворка. Справочник — общий источник правил для программиста и агента;
этот навык не содержит отдельной таблицы defaults.

## Найти подходящий контракт

1. Найдите checkout фреймворка, подключённый проектом через include/toolchain.
   Проверьте `STM32_CMAKE_YML_VERSION` в `stm32_yml.cmake` и Git commit, если
   доступен. `stm32_cmake_yml_version` в YAML описывает ожидание конфига и не
   выбирает установленный код. Совпадение строки 0.9.2 не доказывает наличие фикса.
2. Откройте [индекс документации RU](../../docs/ru/index.md) или
   [EN](../../docs/en/index.md), затем [машиночитаемый индекс](../../docs/reference-index.json).
   Он связывает YAML-ключи с карточками, `CFG-*`, тестами и `E*`.
3. Прочитайте [семантику](../../docs/ru/reference/0.9.2/semantics.md) /
   [semantics](../../docs/en/reference/0.9.2/semantics.md), нужные карточки и все
   применимые errata. Сопоставьте commit исправления с фактическим checkout.
   Статус «подготовлено» не означает «слито», а «слито» не означает «выпущено».

Относительные ссылки выше рассчитаны на навык внутри репозитория. Если навык
установлен отдельно, ищите те же `docs/...` в checkout фреймворка потребителя,
а не относительно глобальной папки skills. При отсутствии справочника или
несовпадении версии исследуйте используемый код и явно обозначьте непроверенные
предположения; не применяйте молча правила другой версии.

## Изменить конфигурацию

- Используйте YAML для принадлежащих ему опций. Toolchain, Arduino-обёртки,
  пользовательские targets и линковка модулей могут требовать CMake: не запрещайте
  такие изменения, если они нужны для задачи пользователя.
- Проверьте backend, источник IOC/defaults, выбранный профиль и cache overrides.
  Учитывайте отличия отсутствия/null от false/0/[] и базу относительных путей.
- Сохраняйте простые YAML-скаляры без лишних кавычек. Кавычки не исправляют
  неподдерживаемую CMake-нормализацию пробелов внутри аргументов.
- Сначала выбирайте документированный обход применимого дефекта. Изменение
  runtime-реализации или контракта оформляйте отдельно и явно, в пределах задачи.
- Не приписывайте конфигурации гарантии сборки или исполнения. Например,
  успешный Configure и наличие CRC-команды не доказывают корректность CRC.

## Проверить и объяснить результат

Сохраните используемые проектом генератор и toolchain. Для задачи конфигурации
выполните Configure/Generate и подходящие сценарии из `tests/cases.json` согласно
[тестированию RU](../../docs/ru/testing.md) / [EN](../../docs/en/testing.md).
Не запускайте полную сборку только потому, что была изменена YAML-опция.

При повторной настройке не считайте пропущенный `-D` удалённым из кэша. Выбирайте
между проверкой cache reuse и свежей build-папкой согласно задаче и errata.
`tests: []` в индексе означает отсутствие автоматического покрытия, а не ошибку.
Не обосновывайте весь контракт одним частично покрывающим тестом.

В результате назовите изменённые опции, проверенную версию/commit, выполненные
проверки и применимый `CFG-*`/`E*`, если он объясняет решение. При добавлении или
изменении контракта обновите reference RU/EN, индекс, errata и регрессию по
[правилам сопровождения](../../docs/ru/maintenance.md) /
[maintenance](../../docs/en/maintenance.md).

## English routing summary

Locate the consumer's actual framework checkout and commit. Resolve option cards
through `docs/reference-index.json`, read shared semantics and applicable errata,
then change YAML or consumer CMake as the task requires. The English reference
and maintenance links above contain the same contracts. Keep version intent,
actual implementation, prepared fixes and released fixes distinct. Validate the
requested phase and report its limits; never maintain a second option catalog
inside this skill.
