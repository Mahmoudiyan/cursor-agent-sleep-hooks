$ErrorActionPreference = 'SilentlyContinue'

$CursorDir = Join-Path $env:USERPROFILE '.cursor'
$HooksDir = Join-Path $CursorDir 'hooks'
$StopScript = Join-Path $HooksDir 'prevent-sleep-stop.cmd'

if (Test-Path $StopScript) {
    & cmd /c $StopScript
}

Remove-Item (Join-Path $CursorDir 'hooks.json') -Force
Remove-Item (Join-Path $HooksDir 'prevent-sleep-*') -Force
Remove-Item (Join-Path $CursorDir 'agent-caffeinate.pid') -Force
Remove-Item (Join-Path $CursorDir 'agent-caffeinate.count') -Force

Write-Host 'Removed Cursor agent sleep hooks.'
