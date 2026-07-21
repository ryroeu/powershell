<#
.SYNOPSIS
    Reports system uptime and whether it exceeds a reboot threshold.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [ValidateRange(1, 3650)]
    [int]$ThresholdDays = 30
)

if ($IsWindows) {
    $platform = 'Windows'
    $lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
}
elseif ($IsLinux) {
    $platform = 'Linux'
    $lastBootTime = (Get-Date).Subtract([timespan]::FromMilliseconds([Environment]::TickCount64))
}
elseif ($IsMacOS) {
    $platform = 'macOS'
    $lastBootTime = (Get-Date).Subtract([timespan]::FromMilliseconds([Environment]::TickCount64))
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}

$uptime = (Get-Date) - $lastBootTime
[pscustomobject]@{
    ComputerName   = [Environment]::MachineName
    Platform       = $platform
    LastBootTime   = $lastBootTime
    Uptime         = $uptime
    UptimeDays     = [Math]::Round($uptime.TotalDays, 2)
    ThresholdDays  = $ThresholdDays
    RebootRequired = $uptime.TotalDays -gt $ThresholdDays
}
