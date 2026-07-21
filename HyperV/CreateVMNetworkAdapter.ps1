<#
.SYNOPSIS
    Adds a network adapter to a Hyper-V virtual machine.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$VMName,

    [Parameter(Mandatory)]
    [string]$SwitchName,

    [Parameter(Mandatory)]
    [string]$Name,

    [string]$ComputerName,

    [switch]$Legacy
)

$parameters = @{
    VMName     = $VMName
    SwitchName = $SwitchName
    Name       = $Name
    IsLegacy   = $Legacy
}
if ($ComputerName) { $parameters.ComputerName = $ComputerName }

if ($PSCmdlet.ShouldProcess(($ComputerName ?? $env:COMPUTERNAME), "Add adapter '$Name' to VM '$VMName'")) {
    Add-VMNetworkAdapter @parameters
}
