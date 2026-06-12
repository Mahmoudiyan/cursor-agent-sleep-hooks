$ErrorActionPreference = 'SilentlyContinue'

$Dir = Join-Path $env:USERPROFILE '.cursor'
$PidFile = Join-Path $Dir 'agent-caffeinate.pid'
$CountFile = Join-Path $Dir 'agent-caffeinate.count'
$Daemon = Join-Path $PSScriptRoot 'prevent-sleep-daemon.ps1'

New-Item -ItemType Directory -Force -Path $Dir | Out-Null

$count = 0
if (Test-Path $CountFile) {
    $raw = (Get-Content $CountFile -Raw).Trim()
    if ($raw -match '^\d+$') {
        $count = [int]$raw
    }
}

$count++
Set-Content -Path $CountFile -Value $count -NoNewline

if ($count -eq 1) {
    if (Test-Path $PidFile) {
        $existingPid = (Get-Content $PidFile -Raw).Trim()
        if ($existingPid -match '^\d+$' -and (Get-Process -Id ([int]$existingPid) -ErrorAction SilentlyContinue)) {
            exit 0
        }
        Remove-Item $PidFile -Force
    }

    $proc = Start-Process powershell `
        -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass', '-File', "`"$Daemon`"" `
        -PassThru

    if ($proc) {
        Set-Content -Path $PidFile -Value $proc.Id -NoNewline
    }
}

exit 0
