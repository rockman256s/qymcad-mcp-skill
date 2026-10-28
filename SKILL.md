---
name: qymcad-assistant
description: Set up QymCAD (an open-source parametric CAD on OpenCASCADE) with its AI-assistant MCP server, and model parts in a live QymCAD window through it - sketches, extrusions, fillets, holes, parameters - looking at screenshots of the window after each shaping step. Use when asked to install, build or connect QymCAD / qymcad-mcp, or to build a part from a drawing in QymCAD.
---

# QymCAD assistant

**English** · [Русский](SKILL.ru.md)

QymCAD is a desktop parametric CAD (Rust, OpenCASCADE 7.9.3). The branch
`feat/ai-assistant` of `rockman256s/QymCAD` adds:

- **`qymcad-mcp`** - a Model Context Protocol server (stdio) with 20 tools;
- **a live mode in the QymCAD window** - with *Settings -> General -> "Let an AI
  assistant work in this window"* ticked, every tool call is made in the open
  window as one step: drawn, written on the status line, undoable with Ctrl+Z.
  `screenshot` returns a PNG of the window so you can see what you built.

Without a window listening, the server builds a document in its own process
(headless) and can save `.qcad` / export STEP and STL.

Until the upstream project (`QymIs-Tech/QymCAD`) merges this, the live mode exists only in
a build from the branch above - the packaged QymCAD releases do not have it.

## 1. Set up

### Windows 10/11 x64 (verified)

Run in PowerShell (it installs Git, CMake, Rust, VS 2022 Build Tools with C++,
builds OCCT 7.9.3 into `C:\occt`, clones and builds the branch, installs both
programs with the OCCT DLLs beside them into
`%LOCALAPPDATA%\Programs\QymCAD-assistant`, and registers the MCP server with
Claude Code when its CLI is found):

```powershell
irm https://raw.githubusercontent.com/rockman256s/qymcad-mcp-skill/main/scripts/setup-windows.ps1 -OutFile setup-windows.ps1
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
```

Read the script before running it. Expect: ~10 GB of disk, UAC prompts from the
installers, 20-40 min for OCCT on the first run, ~10 min for QymCAD. It is
idempotent: what is already there is skipped.

Things that bite on Windows, all handled by the script:

- **Paths over 260 characters.** Clone and build under a short path
  (`$HOME\src\QymCAD`, `CARGO_TARGET_DIR` like `C:\qt`), and
  `git config core.longpaths true`. `Expand-Archive` fails on this repository;
  use `git clone` or `tar`.
- **OCCT is built from source**, exactly 7.9.3, with
  `BUILD_RELEASE_DISABLE_EXCEPTIONS=OFF` and `INSTALL_DIR_LAYOUT=Unix` (see the
  repository's `packaging/README.md`). Generator: `-G "Visual Studio 17 2022" -A x64`.
- **Build environment:** `OCCT_INCLUDE_DIR=C:\occt\include\opencascade`,
  `OCCT_LIB_DIR=C:\occt\lib`, `OCCT_ROOT=C:\occt`; at run time the OCCT DLLs must
  be on `PATH` or beside the `.exe`.

### Linux (not verified here - follow the repository's packaging/README.md)

```bash
# deps: build-essential cmake git curl, Rust via rustup
curl -sSL -o occt.tar.gz https://github.com/Open-Cascade-SAS/OCCT/archive/refs/tags/V7_9_3.tar.gz && tar xf occt.tar.gz
cmake -S OCCT-7_9_3 -B occt-build -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRARY_TYPE=Shared \
  -DINSTALL_DIR=$HOME/occt -DINSTALL_DIR_LAYOUT=Unix -DBUILD_RELEASE_DISABLE_EXCEPTIONS=OFF \
  -DBUILD_MODULE_Draw=OFF -DBUILD_MODULE_Visualization=OFF -DBUILD_DOC_Overview=OFF \
  -DUSE_FREETYPE=OFF -DUSE_TK=OFF -DUSE_FREEIMAGE=OFF -DUSE_RAPIDJSON=OFF -DUSE_DRACO=OFF -DUSE_OPENGL=OFF -DUSE_GLES2=OFF
cmake --build occt-build --target install -j"$(nproc)"
git clone -b feat/ai-assistant https://github.com/rockman256s/QymCAD.git && cd QymCAD
export OCCT_INCLUDE_DIR=$HOME/occt/include/opencascade OCCT_LIB_DIR=$HOME/occt/lib OCCT_ROOT=$HOME/occt
cargo build --release --bin qymcad --bin qymcad-mcp
export LD_LIBRARY_PATH=$HOME/occt/lib   # for both programs at run time
```

### Register the MCP server

- **Claude Code:** `claude mcp add --scope user qymcad -- <path to qymcad-mcp>`
  (on Linux add `-e LD_LIBRARY_PATH=$HOME/occt/lib`). Check: `claude mcp get qymcad`
  shows `Connected`.
- **Claude Desktop:** add to `claude_desktop_config.json`
  (`%APPDATA%\Claude\` on Windows) and restart the app:
  ```json
  { "mcpServers": { "qymcad": { "command": "C:\\Users\\<you>\\AppData\\Local\\Programs\\QymCAD-assistant\\qymcad-mcp.exe" } } }
  ```

The tools appear in **new** sessions only.

### Turn on the live mode

Start the QymCAD built from the branch (`qymcad.exe` in the install folder) and
tick *Settings -> General -> Let an AI assistant work in this window*. The window
then writes a door file (`assistant.json`: port and token) into its data folder
(`%APPDATA%\qymis\qymcad\data`, `~/.local/share/qymcad`) and the server finds it
by itself. `describe_document` answers `"where": "window"` when connected,
`"file"` when headless.

## 2. Model a part

Units: millimetres and degrees. A drawing in inches: multiply by 25.4.

Workflow that works:

1. `describe_document` - see where you are and what exists.
2. Read the drawing **before** drawing anything. Write down every dimension and
   decide which faces each feature sits on. Undimensioned sizes: measure them
   off the drawing in proportion to known ones, and say what you assumed.
3. Build the main body from a side profile when the part is prismatic: one
   `sketch` with a closed `polyline` on `XZ` (x along the length, y = height),
   then `extrude` by the width. An XZ sketch extrudes toward -Y.
4. `screenshot` with `"view": "iso"` after every step that shapes the part and
   **compare it with the drawing** - placement of steps, ribs, holes. The numbers
   tell you what was built; the picture tells you whether it is the right thing.
   The default iso view looks from +X -Y +Z: X runs to the lower right, Y to the
   upper right, like a usual isometric drawing.
5. Picking faces or edges: `describe_body` lists them with centres, normals,
   ends and radii; choose by geometry (e.g. normal `[0,0,1]` and the highest
   centre = top face). Never guess ids.
6. Holes through: a `sketch` of circles on `XY`, then `extrude` with
   `operation: "cut"`, `direction: "both"`, `through: true`, `body: <id>`.
   A circle drawn inside a closed contour becomes a hole of that contour.
7. A step came out wrong: `undo` (with `count`), then redo it right. Do not build
   over a mistake.
8. Check volumes against a hand calculation when the shape is simple enough.
9. Drive sizes by parameters when the person may want to change them:
   `set_parameter` then `set_dimension` (`feature`, `key` like `height`).

Facts of the model worth knowing:

- A part is one body: every `extrude` with `operation: "add"` and every
  `primitive` is united into the part's body.
- A cut right through leaves the pieces as several bodies of one part.
- A body taken up by a later feature (fillet, cut, boolean) is no longer
  operable; act on the id the latest answer lists.
- In the window, `new_document` and `open_document` are refused: the document
  belongs to the person; ask them to open or start one. `save_document` needs a
  `path` there and writes a copy.

## 3. Troubleshooting

- `"where": "file"` while QymCAD is open: the setting is off, or the window is
  the packaged release (no live mode), or a stale `assistant.json` from a killed
  window - restart QymCAD.
- The server does not start: OCCT DLLs / `LD_LIBRARY_PATH` are missing.
- A tool answer lists `failed` nodes: read the reason code, `undo`, change the
  inputs.
- `screenshot` refused: no window listening.
