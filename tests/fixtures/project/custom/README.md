# Consumer wrappers / Пользовательские обёртки

Synthetic OBJECT libraries model a consumer dependency chain:
`Custom::App` → `Custom::Hal` → `Arduino::Definitions` + `Arduino::Core`.
They test CMake wiring only, not peripheral drivers. Matching `driver` directory
names exercise binary-directory naming from the full relative path.

Синтетические OBJECT-библиотеки моделируют цепочку зависимостей проекта.
Они проверяют связи CMake, а не работу драйверов периферии. Одинаковые имена
каталогов `driver` проверяют формирование бинарного пути из полного относительного
пути. Исходники не компилируются и не являются тестовой прошивкой.
