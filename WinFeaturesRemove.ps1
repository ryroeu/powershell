<#
.SYNOPSIS
    Removes selected Windows Server roles or features and optionally their payloads.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string[]]$Name,

    [string]$ComputerName,

    [switch]$RemovePayload,

    [switch]$Restart
)

$parameters = @{
    Name    = $Name
    Remove  = $RemovePayload
    Restart = $Restart
}
if ($ComputerName) {
    $parameters.ComputerName = $ComputerName
}

if ($PSCmdlet.ShouldProcess(($ComputerName ?? $env:COMPUTERNAME), "Remove Windows feature(s): $($Name -join ', ')")) {
    Uninstall-WindowsFeature @parameters
}
