# Тексты релизов / Release notes

[Документация RU](../ru/index.md) · [Documentation EN](../en/index.md)

| Версия / Version | Русский | English |
| --- | --- | --- |
| 0.10.1 | [Текст](v0.10.1.md) | [Text](v0.10.1.en.md) |

Файлы готовятся в релизной ветке и входят в коммит до создания тега.
GitHub Release использует русский текст, затем английский в свёрнутом блоке:

Files are prepared on the release branch and committed before tagging.
GitHub Release uses the Russian text followed by collapsed English:

```html
<details>
<summary>English</summary>

<!-- Вставьте содержимое .en.md / Paste the .en.md content here -->

</details>
```

Сохраняйте пустые строки; не добавляйте `open`. Исходные файлы не оборачиваются
в details. Ссылки с тегом заработают после его публикации. Исправления после
выпуска отмечаются отдельным коммитом и синхронизируются с GitHub Release.

Keep blank lines and omit `open`. Source files contain plain Markdown, without
a details wrapper. Tag links become available after publication. Later corrections
are recorded in a separate commit and synchronized with GitHub Release.
