$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$CursorDir = Join-Path $env:USERPROFILE '.cursor'
$HooksDir = Join-Path $CursorDir 'hooks'
$Src = Join-Path $Root 'windows'

if (-not (Test-Path $Src)) {
    throw "Missing platform files: $Src"
}

New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null

Copy-Item (Join-Path $Src 'hooks.json') (Join-Path $CursorDir 'hooks.json') -Force
Copy-Item (Join-Path $Src 'prevent-sleep-*') $HooksDir -Force

Write-Host "Installed Windows hooks to $CursorDir"
Write-Host "Restart Cursor, then check Settings -> Hooks."
