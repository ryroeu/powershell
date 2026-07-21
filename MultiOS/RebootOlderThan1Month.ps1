<#
.SYNOPSIS
    Schedules a reboot when system uptime exceeds a threshold.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateRange(1, 3650)]
    [int]$ThresholdDays = 30,

    [ValidateRange(0, 1440)]
    [int]$DelayMinutes = 5,

    [switch]$Force
)

if ($IsWindows) {
    $lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
}
elseif ($IsLinux) {
    $lastBootTime = (Get-Date).Subtract([timespan]::FromMilliseconds([Environment]::TickCount64))
}
elseif ($IsMacOS) {
    $lastBootTime = (Get-Date).Subtract([timespan]::FromMilliseconds([Environment]::TickCount64))
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}

$uptime = (Get-Date) - $lastBootTime
$report = [pscustomobject]@{
    ComputerName    = [Environment]::MachineName
    LastBootTime    = $lastBootTime
    UptimeDays      = [Math]::Round($uptime.TotalDays, 2)
    ThresholdDays   = $ThresholdDays
    RebootScheduled = $false
}
if ($uptime.TotalDays -le $ThresholdDays) {
    $report
    return
}

$target = [Environment]::MachineName
if (-not $PSCmdlet.ShouldProcess($target, "Schedule reboot in $DelayMinutes minute(s)")) {
    $report
    return
}

if ($IsWindows) {
    $arguments = @('/r', '/t', ($DelayMinutes * 60), '/c', 'Reboot scheduled because uptime exceeded policy threshold.')
    if ($Force) { $arguments += '/f' }
    & "$env:SystemRoot\System32\shutdown.exe" @arguments
}
else {
    if ([Environment]::UserName -ne 'root') {
        throw 'Run this script as root to schedule a reboot on Linux or macOS.'
    }
    & shutdown -r "+$DelayMinutes" 'Reboot scheduled because uptime exceeded policy threshold.'
}
if ($LASTEXITCODE -ne 0) { throw "shutdown failed with exit code $LASTEXITCODE." }

$report.RebootScheduled = $true
$report
