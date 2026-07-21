<#
.SYNOPSIS
    Lists installed Windows programs from uninstall registry entries.
#>

[CmdletBinding()]
param(
    [switch]$IncludeCurrentUser
)

if (-not $IsWindows) { throw 'This script requires Windows.' }
$paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
if ($IncludeCurrentUser) {
    $paths += 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
}

Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
    Where-Object DisplayName |
    Sort-Object Publisher, DisplayName, DisplayVersion -Unique |
    Select-Object @{ Name = 'Vendor'; Expression = { $_.Publisher } },
    @{ Name = 'Name'; Expression = { $_.DisplayName } },
    @{ Name = 'Version'; Expression = { $_.DisplayVersion } },
    InstallDate, InstallLocation, UninstallString, PSPath
