# Arduino library discovery fixture / Проверка поиска библиотек Arduino

This is a synthetic core layout, not a complete Arduino distribution. The runner
links `cores` to pinned Arduino Core 2.12.0; `libraries/Probe` is a test-owned
CMake wrapper. No upstream files are modified. The fixture checks discovery,
explicit linkage, definitions propagation and clearing on reconfiguration.
It does not test compilation or compatibility of upstream library wrappers.

Это синтетическая структура ядра, а не полная поставка Arduino. Runner создаёт
ссылку `cores` на закреплённое ядро 2.12.0; `libraries/Probe` — тестовая CMake-
обёртка. Исходники Arduino не изменяются. Проверяются поиск библиотеки, явное
подключение, передача определений и очистка при перенастройке. Компиляция и
совместимость штатных обёрток библиотек здесь не проверяются.
