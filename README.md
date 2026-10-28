# qymcad-mcp-skill

A skill for AI agents (Claude Code, Claude Desktop, any agent that reads `SKILL.md`)
to set up **[QymCAD](https://github.com/QymIs-Tech/QymCAD)** with its AI-assistant MCP server
and to model parts in a live QymCAD window - the agent makes every step in the
window, the person watches it happen and can undo or take over at any step, and
the agent looks at screenshots of the window to check what it built.

The code lives on the branch [`feat/ai-assistant`](https://github.com/rockman256s/QymCAD/tree/feat/ai-assistant)
of the fork [`rockman256s/QymCAD`](https://github.com/rockman256s/QymCAD) and is proposed to the upstream
project. Until it is merged, the live mode needs a build from that branch.

## What is in here

| File | What it is |
| --- | --- |
| [`SKILL.md`](SKILL.md) | The skill: how to set everything up and how to model with the tools |
| [`scripts/setup-windows.ps1`](scripts/setup-windows.ps1) | One script for Windows: toolchain, OCCT 7.9.3, build, install, MCP registration |

## Message to an agent

Paste this to an agent (for example Claude Opus in Claude Code) on the machine
where QymCAD should run:

> Set up QymCAD with its AI-assistant MCP server on this computer and connect it
> to yourself. Follow the skill at
> https://github.com/rockman256s/qymcad-mcp-skill - read `SKILL.md` first, then for Windows
> read and run `scripts/setup-windows.ps1` (for Linux follow the Linux section).
> Install the skill itself too: copy `SKILL.md` into
> `~/.claude/skills/qymcad-assistant/SKILL.md`. When the build is done, start
> `qymcad.exe` from `%LOCALAPPDATA%\Programs\QymCAD-assistant`, ask me to tick
> Settings -> General -> "Let an AI assistant work in this window", and tell me
> to open a new session where the `qymcad` tools are available. Report what you
> installed and anything that failed, with the output.

Then, in the new session:

> Build this part in QymCAD from the drawing I attach. Work in the open window,
> take a screenshot after each step that shapes the part and compare it with the
> drawing; undo and redo a step that comes out wrong.

## Tools of the server

`sketch`, `extrude`, `revolve`, `primitive`, `fillet`, `chamfer`, `shell`, `hole`,
`boolean`, `set_parameter`, `set_dimension`, `describe_document`, `describe_body`,
`new_document`, `open_document`, `save_document`, `export`, and in a window
`screenshot`, `view`, `undo`.

## Licence

QymCAD is AGPL-3.0-or-later; the code on the branch is under the same licence.
This skill is offered under the same terms.
