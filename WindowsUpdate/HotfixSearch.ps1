<#
.SYNOPSIS
    Lists installed Windows hotfixes or searches for specific KB identifiers.
#>

[CmdletBinding()]
param(
    [Alias('KB')]
    [string[]]$Id,

    [string[]]$ComputerName = @($env:COMPUTERNAME),

    [pscredential]$Credential
)

if (-not $IsWindows) {
    throw 'This script requires Windows.'
}

$parameters = @{ ComputerName = $ComputerName; ErrorAction = 'Stop' }
if ($Id) { $parameters.Id = $Id }
if ($Credential) { $parameters.Credential = $Credential }

Get-HotFix @parameters | Sort-Object PSComputerName, InstalledOn -Descending
