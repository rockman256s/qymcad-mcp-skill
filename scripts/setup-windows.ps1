# Sets up QymCAD with the AI-assistant MCP server on Windows 10/11 x64.
#
# Steps (each skipped when already done):
#   1. Git, CMake, GitHub CLI, Rustup, VS 2022 Build Tools with the C++ workload (winget; UAC prompts appear)
#   2. OCCT 7.9.3 built from source into C:\occt with the flags the project requires
#   3. the branch cloned into a short path, built in release
#   4. qymcad.exe + qymcad-mcp.exe + OCCT DLLs installed into %LOCALAPPDATA%\Programs\QymCAD-assistant
#   5. the MCP server registered with Claude Code (user scope) if its CLI is found
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1 [-Repo <url>] [-Branch <name>] [-Src <dir>]
param(
    [string]$Repo = "https://github.com/rockman256s/QymCAD.git",
    [string]$Branch = "feat/ai-assistant",
    [string]$Src = "$HOME\src\QymCAD",
    [string]$Occt = "C:\occt",
    [string]$Target = "C:\qt",
    [string]$Install = "$env:LOCALAPPDATA\Programs\QymCAD-assistant"
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
function Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }
function Refresh-Path { $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User") + ";$env:USERPROFILE\.cargo\bin" }

Step "1. Tools"
$packages = @(
    @{ id = "Git.Git"; probe = "git" },
    @{ id = "Kitware.CMake"; probe = "cmake" },
    @{ id = "GitHub.cli"; probe = "gh" },
    @{ id = "Rustlang.Rustup"; probe = "rustup" }
)
Refresh-Path
foreach ($p in $packages) {
    if (Get-Command $p.probe -ErrorAction SilentlyContinue) { Write-Host "  $($p.id): present"; continue }
    winget install --id $p.id -e --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
}
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vc = if (Test-Path $vswhere) { & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath } else { $null }
if (-not $vc) {
    winget install --id Microsoft.VisualStudio.2022.BuildTools -e --silent --accept-source-agreements --accept-package-agreements --disable-interactivity `
        --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
} else { Write-Host "  VS C++ build tools: $vc" }
Refresh-Path
rustup toolchain install stable --profile minimal -c rustfmt,clippy
rustup default stable

Step "2. OCCT 7.9.3 -> $Occt"
if (Test-Path "$Occt\lib\TKernel.lib") {
    Write-Host "  present"
} else {
    $work = "$env:TEMP\occt-src"
    New-Item -ItemType Directory -Force $work | Out-Null
    curl.exe -sSL -o "$work\occt.tar.gz" https://github.com/Open-Cascade-SAS/OCCT/archive/refs/tags/V7_9_3.tar.gz
    tar xf "$work\occt.tar.gz" -C $work
    $occtSrc = (Get-ChildItem $work -Directory -Filter "OCCT-*" | Select-Object -First 1).FullName
    cmake -S $occtSrc -B "$work\build" -G "Visual Studio 17 2022" -A x64 "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" "-DBUILD_LIBRARY_TYPE=Shared" `
        "-DINSTALL_DIR=$($Occt.Replace('\','/'))" "-DINSTALL_DIR_LAYOUT=Unix" "-DBUILD_RELEASE_DISABLE_EXCEPTIONS=OFF" `
        "-DBUILD_MODULE_Draw=OFF" "-DBUILD_MODULE_Visualization=OFF" "-DBUILD_DOC_Overview=OFF" "-DUSE_FREETYPE=OFF" "-DUSE_TK=OFF" `
        "-DUSE_FREEIMAGE=OFF" "-DUSE_RAPIDJSON=OFF" "-DUSE_DRACO=OFF" "-DUSE_OPENGL=OFF" "-DUSE_GLES2=OFF"
    if ($LASTEXITCODE -ne 0) { throw "OCCT configure failed" }
    cmake --build "$work\build" --config Release --target install -- /m
    if ($LASTEXITCODE -ne 0) { throw "OCCT build failed" }
}

Step "3. QymCAD ($Branch) -> $Src"
if (Test-Path "$Src\.git") {
    git -C $Src fetch origin $Branch
    git -C $Src checkout $Branch
    git -C $Src pull --ff-only origin $Branch
} else {
    New-Item -ItemType Directory -Force (Split-Path $Src) | Out-Null
    git -c core.longpaths=true clone -b $Branch $Repo $Src
    git -C $Src config core.longpaths true
}
$env:OCCT_INCLUDE_DIR = "$Occt\include\opencascade"
$env:OCCT_LIB_DIR = "$Occt\lib"
$env:OCCT_ROOT = $Occt
$env:CARGO_TARGET_DIR = $Target
$env:Path = "$Occt\bin;$env:Path"
Push-Location $Src
cargo build --release --bin qymcad -p qymcad --bin qymcad-mcp -p qymcad-mcp
$built = $LASTEXITCODE
Pop-Location
if ($built -ne 0) { throw "the QymCAD build failed" }

Step "4. Install -> $Install"
New-Item -ItemType Directory -Force $Install | Out-Null
Copy-Item "$Target\release\qymcad.exe", "$Target\release\qymcad-mcp.exe" $Install -Force
Copy-Item "$Occt\bin\*.dll" $Install -Force
$mcp = Join-Path $Install "qymcad-mcp.exe"

Step "5. Register the MCP server"
$claude = Get-Command claude -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $claude) { $claude = Get-ChildItem "$env:APPDATA\Claude\claude-code" -Recurse -Filter claude.exe -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1 -ExpandProperty FullName }
if ($claude) {
    & $claude mcp remove qymcad -s user 2>$null | Out-Null
    & $claude mcp add --scope user qymcad -- $mcp
} else {
    Write-Host "  Claude Code CLI not found: claude mcp add --scope user qymcad -- `"$mcp`""
}
Write-Host "  Claude Desktop: add to %APPDATA%\Claude\claude_desktop_config.json and restart the app:"
Write-Host ('  { "mcpServers": { "qymcad": { "command": "' + $mcp.Replace('\', '\\') + '" } } }')

Step "Done"
Write-Host "Start $Install\qymcad.exe, tick Settings -> General -> 'Let an AI assistant work in this window',"
Write-Host "then open a NEW Claude session: the qymcad tools appear there."
