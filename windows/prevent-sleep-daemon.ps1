$ErrorActionPreference = 'SilentlyContinue'

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class CursorNativePower {
    [DllImport("kernel32.dll")]
    public static extern uint SetThreadExecutionState(uint esFlags);
}
'@

$continuous = [uint32]0x80000000
$systemRequired = [uint32]0x00000001
$displayRequired = [uint32]0x00000002
$flags = $continuous -bor $systemRequired -bor $displayRequired

[void][CursorNativePower]::SetThreadExecutionState($flags)

while ($true) {
    Start-Sleep -Seconds 60
}
