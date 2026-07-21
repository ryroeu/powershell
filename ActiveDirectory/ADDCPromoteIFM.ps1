<#
.SYNOPSIS
    Promotes the local Windows Server to a domain controller using installation media.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$DomainName,

    [Parameter(Mandatory)]
    [string]$InstallationMediaPath,

    [Parameter(Mandatory)]
    [securestring]$SafeModeAdministratorPassword,

    [pscredential]$Credential,

    [string]$SiteName,

    [string]$DatabasePath = 'C:\Windows\NTDS',

    [string]$LogPath = 'C:\Windows\NTDS',

    [string]$SysvolPath = 'C:\Windows\SYSVOL',

    [switch]$NoRebootOnCompletion
)

if (-not (Test-Path -LiteralPath $InstallationMediaPath -PathType Container)) {
    throw "Installation media path '$InstallationMediaPath' was not found."
}
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Install Active Directory Domain Services role')) {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
}
Import-Module ADDSDeployment -ErrorAction Stop

$parameters = @{
    DomainName                    = $DomainName
    InstallationMediaPath         = $InstallationMediaPath
    SafeModeAdministratorPassword = $SafeModeAdministratorPassword
    InstallDns                    = $true
    NoGlobalCatalog               = $false
    DatabasePath                  = $DatabasePath
    LogPath                       = $LogPath
    SysvolPath                    = $SysvolPath
    NoRebootOnCompletion          = $NoRebootOnCompletion
    Force                         = $true
}
if ($Credential) { $parameters.Credential = $Credential }
if ($SiteName) { $parameters.SiteName = $SiteName }

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Promote from IFM to domain controller for '$DomainName'")) {
    Install-ADDSDomainController @parameters
}
