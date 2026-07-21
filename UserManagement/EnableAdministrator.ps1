<#
.SYNOPSIS
    Enables a local account and optionally assigns a new password.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$Name = 'Administrator',

    [securestring]$Password
)

$user = Get-LocalUser -Name $Name -ErrorAction Stop
if ($PSCmdlet.ShouldProcess($Name, 'Enable local user account')) {
    $user | Enable-LocalUser
    if ($Password) {
        Set-LocalUser -Name $Name -Password $Password
    }
    Get-LocalUser -Name $Name
}
