# qymcad-mcp-skill

[English](README.md) · **Русский**

Скил для ИИ-агентов (Claude Code, Claude Desktop и любых агентов, которые читают `SKILL.md`):
как развернуть **[QymCAD](https://github.com/QymIs-Tech/QymCAD)** вместе с MCP-сервером ИИ-ассистента
и моделировать детали в живом окне QymCAD. Агент делает каждый шаг прямо в окне, человек видит это,
может отменить любой шаг или перехватить работу, а агент смотрит на снимки окна и сверяет, что построил.

Код лежит в ветке [`feat/ai-assistant`](https://github.com/rockman256s/QymCAD/tree/feat/ai-assistant)
форка [`rockman256s/QymCAD`](https://github.com/rockman256s/QymCAD) и предложен в основной проект.
Пока его не приняли, живой режим есть только в сборке из этой ветки.

## Что здесь лежит

| Файл | Что это |
| --- | --- |
| [`SKILL.md`](SKILL.md) | Сам скил (на английском — его читает агент): как всё развернуть и как моделировать инструментами |
| [`SKILL.ru.md`](SKILL.ru.md) | Тот же скил по-русски — для людей |
| [`scripts/setup-windows.ps1`](scripts/setup-windows.ps1) | Один скрипт для Windows: инструменты, OCCT 7.9.3, сборка, установка, регистрация MCP |

## Сообщение агенту

Вставьте это агенту (например, Claude Opus в Claude Code) на компьютере, где должен работать QymCAD:

> Разверни на этом компьютере QymCAD с MCP-сервером ИИ-ассистента и подключи его к себе.
> Следуй скилу https://github.com/rockman256s/qymcad-mcp-skill — сначала прочитай `SKILL.md`,
> потом для Windows прочитай и запусти `scripts/setup-windows.ps1` (для Linux — раздел Linux).
> Установи и сам скил: скопируй `SKILL.md` в `~/.claude/skills/qymcad-assistant/SKILL.md`.
> Когда сборка закончится, запусти `qymcad.exe` из `%LOCALAPPDATA%\Programs\QymCAD-assistant`,
> попроси меня поставить галочку «Настройки → Общие → Разрешить ИИ-ассистенту работать в этом окне»
> и скажи открыть новую сессию, где будут инструменты `qymcad`. Отчитайся, что установил и что
> не получилось, с выводом команд.

Потом, в новой сессии:

> Построй эту деталь в QymCAD по чертежу, который я прикладываю. Работай в открытом окне, после
> каждого шага, который меняет форму, делай снимок и сравнивай его с чертежом; шаг, который вышел
> неправильно, отменяй и делай заново.

## Инструменты сервера

`sketch`, `extrude`, `revolve`, `primitive`, `fillet`, `chamfer`, `shell`, `hole`,
`boolean`, `set_parameter`, `set_dimension`, `describe_document`, `describe_body`,
`new_document`, `open_document`, `save_document`, `export`, а в окне ещё
`screenshot`, `view`, `undo`.

## Лицензия

QymCAD распространяется под AGPL-3.0-or-later; код в ветке — под той же лицензией.
Этот скил — на тех же условиях.
