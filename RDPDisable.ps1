<#
.SYNOPSIS
    Disables Remote Desktop connections and its firewall rules.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

if ($PSCmdlet.ShouldProcess('Local computer', 'Disable Remote Desktop')) {
    Set-ItemProperty -LiteralPath 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 1 -Type DWord
    Disable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue
}
