$ErrorActionPreference = 'SilentlyContinue'

$Dir = Join-Path $env:USERPROFILE '.cursor'
$PidFile = Join-Path $Dir 'agent-caffeinate.pid'
$CountFile = Join-Path $Dir 'agent-caffeinate.count'

$count = 0
if (Test-Path $CountFile) {
    $raw = (Get-Content $CountFile -Raw).Trim()
    if ($raw -match '^\d+$') {
        $count = [int]$raw
    }
}

if ($count -le 0) {
    exit 0
}

$count--
Set-Content -Path $CountFile -Value $count -NoNewline

if ($count -eq 0 -and (Test-Path $PidFile)) {
    $pidText = (Get-Content $PidFile -Raw).Trim()
    if ($pidText -match '^\d+$') {
        $procId = [int]$pidText
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $PidFile -Force
}

exit 0
