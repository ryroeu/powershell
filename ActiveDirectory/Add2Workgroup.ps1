<#
.SYNOPSIS
    Moves a Windows computer to a workgroup.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$WorkgroupName = 'WORKGROUP',

    [string]$ComputerName = $env:COMPUTERNAME,

    [pscredential]$UnjoinDomainCredential,

    [switch]$Restart
)

$parameters = @{ ComputerName = $ComputerName; WorkgroupName = $WorkgroupName; PassThru = $true; Force = $true; Restart = $Restart }
if ($UnjoinDomainCredential) { $parameters.UnjoinDomainCredential = $UnjoinDomainCredential }
if ($PSCmdlet.ShouldProcess($ComputerName, "Move to workgroup '$WorkgroupName'")) { Add-Computer @parameters }
