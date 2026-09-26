# AGENTS.md

Инструкция для ИИ-агентов и новых участников проекта **stm32-cmake-yml**.
Instructions for AI agents and new contributors ([English](docs/en/maintenance.md#working-with-the-project)).

Порядок ознакомления, рабочий цикл, правила ведения ТЗ и коммитов описаны в
[docs/ru/maintenance.md → «Порядок работы с проектом»](docs/ru/maintenance.md#порядок-работы-с-проектом).
Начните с него.

Кратко:

1. Прочитайте [README](README.md), затем [TODO.md](TODO.md) — там текущая ветка и статус.
2. Требования — в [docs/TECHNICAL_SPECIFICATION.md](docs/TECHNICAL_SPECIFICATION.md);
   текущая ревизия указана в его реквизитах. Копии ТЗ вне репозитория не ведутся.
3. Работайте в ветке `<агент>/<задача>` от актуального main (`codex/`, `claude/`, …).
4. Изменение поведения — только с регрессией, карточкой справочника, CHANGELOG и
   новой ревизией ТЗ (п. 7.4 ТЗ). Перед выпуском — все проверки локально (п. 8.8.7).
5. Коммиты — Conventional Commits на английском, без ссылок на сессии агентов.
