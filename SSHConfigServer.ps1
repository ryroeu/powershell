<#
.SYNOPSIS
    Installs and enables the Windows OpenSSH server.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

$capability = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' -ErrorAction Stop |
    Select-Object -First 1
if (-not $capability) {
    throw 'The OpenSSH.Server Windows capability is not available on this operating system.'
}

if ($capability.State -ne 'Installed' -and $PSCmdlet.ShouldProcess('OpenSSH.Server', 'Install Windows capability')) {
    Add-WindowsCapability -Online -Name $capability.Name
}

if ($PSCmdlet.ShouldProcess('sshd', 'Set service startup to Automatic and start it')) {
    Set-Service -Name sshd -StartupType Automatic
    Start-Service -Name sshd
}

Get-Service -Name sshd
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
