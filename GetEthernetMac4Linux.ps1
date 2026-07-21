<#
.SYNOPSIS
    Returns MAC addresses for active network interfaces on Linux.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string]$Name
)

if (-not $IsLinux) {
    throw 'This script is intended for Linux. Use GetEthernetMac4Windows.ps1 on Windows.'
}

[System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
    Where-Object {
        $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback -and
        $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
        (-not $Name -or $_.Name -like $Name)
    } |
    Select-Object Name, Description, InterfaceType, OperationalStatus,
        @{Name = 'MacAddress'; Expression = { $_.GetPhysicalAddress().ToString() -replace '(..)(?=.)', '$1:' } }
