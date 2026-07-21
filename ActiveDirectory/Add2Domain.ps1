<#
.SYNOPSIS
    Joins a Windows computer to an Active Directory domain.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$DomainName,

    [pscredential]$Credential,

    [string]$OUPath,

    [string]$ComputerName = $env:COMPUTERNAME,

    [switch]$Restart
)

$parameters = @{ ComputerName = $ComputerName; DomainName = $DomainName; PassThru = $true; Force = $true; Restart = $Restart }
if ($Credential) { $parameters.Credential = $Credential }
if ($OUPath) { $parameters.OUPath = $OUPath }
if ($PSCmdlet.ShouldProcess($ComputerName, "Join domain '$DomainName'")) { Add-Computer @parameters }
