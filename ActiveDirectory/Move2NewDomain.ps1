<#
.SYNOPSIS
    Moves a Windows computer from its current domain to a target domain.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [string]$TargetDomainName,

    [Parameter(Mandatory)]
    [pscredential]$TargetDomainCredential,

    [Parameter(Mandatory)]
    [pscredential]$SourceDomainCredential,

    [string]$TargetDomainController,

    [string]$TargetOUPath,

    [switch]$Restart
)

$parameters = @{
    ComputerName           = $ComputerName
    DomainName             = $TargetDomainName
    Credential             = $TargetDomainCredential
    UnjoinDomainCredential = $SourceDomainCredential
    PassThru               = $true
    Force                  = $true
    Restart                = $Restart
}
if ($TargetDomainController) { $parameters.Server = $TargetDomainController }
if ($TargetOUPath) { $parameters.OUPath = $TargetOUPath }

if ($PSCmdlet.ShouldProcess($ComputerName, "Move computer to domain '$TargetDomainName'")) {
    Add-Computer @parameters
}
