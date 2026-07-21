<#
.SYNOPSIS
    Installs Windows Server File and Storage Services.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string[]]$Name = @('File-Services'),

    [switch]$Restart
)

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Install Windows feature(s): $($Name -join ', ')")) {
    Install-WindowsFeature -Name $Name -IncludeAllSubFeature -IncludeManagementTools -Restart:$Restart
}
