<#
.SYNOPSIS
    Disables selected Windows Defender Firewall profiles.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateSet('Domain', 'Private', 'Public')]
    [string[]]$FirewallProfile = @('Domain', 'Private', 'Public')
)

if ($PSCmdlet.ShouldProcess(($FirewallProfile -join ', '), 'Disable Windows Defender Firewall profiles')) {
    Set-NetFirewallProfile -Profile $FirewallProfile -Enabled False
}
