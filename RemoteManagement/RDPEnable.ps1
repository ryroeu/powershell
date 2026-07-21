<#
.SYNOPSIS
    Enables Remote Desktop connections and its firewall rules.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

if ($PSCmdlet.ShouldProcess('Local computer', 'Enable Remote Desktop')) {
    Set-ItemProperty -LiteralPath 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0 -Type DWord
    Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
}
