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
    $bootTimeText = (& uptime -s).Trim()
    if ($LASTEXITCODE -ne 0) { throw "uptime failed with exit code $LASTEXITCODE." }
    $lastBootTime = [datetime]::Parse($bootTimeText, [Globalization.CultureInfo]::InvariantCulture)
}
elseif ($IsMacOS) {
    $platform = 'macOS'
    $bootTimeText = (& sysctl -n kern.boottime).Trim()
    if ($LASTEXITCODE -ne 0 -or $bootTimeText -notmatch 'sec\s*=\s*(\d+)') {
        throw "Could not determine the macOS boot time from '$bootTimeText'."
    }
    $lastBootTime = [datetimeoffset]::FromUnixTimeSeconds([long]$Matches[1]).LocalDateTime
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}

$uptime = (Get-Date) - $lastBootTime
[pscustomobject]@{
    ComputerName  = [Environment]::MachineName
    Platform      = $platform
    LastBootTime  = $lastBootTime
    Uptime        = $uptime
    UptimeDays    = [Math]::Round($uptime.TotalDays, 2)
    ThresholdDays = $ThresholdDays
    RebootRequired = $uptime.TotalDays -gt $ThresholdDays
}
