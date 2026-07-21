<#
.SYNOPSIS
    Lists configured WinRM listeners locally or remotely.
#>

[CmdletBinding()]
param(
    [string]$ComputerName = 'localhost',

    [pscredential]$Credential
)

if (-not $IsWindows) {
    throw 'This script requires Windows.'
}

$parameters = @{
    ResourceURI = 'winrm/config/listener'
    Enumerate   = $true
    ErrorAction = 'Stop'
}
if ($ComputerName -notin '.', 'localhost', $env:COMPUTERNAME) {
    $parameters.ComputerName = $ComputerName
}
if ($Credential) {
    $parameters.Credential = $Credential
    $parameters.Authentication = 'Default'
}

Get-WSManInstance @parameters
