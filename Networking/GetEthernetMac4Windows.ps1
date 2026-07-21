<#
.SYNOPSIS
    Retrieves MAC addresses for Windows network adapters.
#>

[CmdletBinding()]
param(
    [string[]]$Name = '*',

    [switch]$PhysicalOnly,

    [switch]$IncludeDisconnected
)

Get-NetAdapter -Name $Name -Physical:$PhysicalOnly |
    Where-Object { $IncludeDisconnected -or $_.Status -eq 'Up' } |
    Select-Object Name, InterfaceDescription, MacAddress, Status, LinkSpeed
