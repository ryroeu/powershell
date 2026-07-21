<#
.SYNOPSIS
    Installs the Windows OpenSSH client capability.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

$capability = Get-WindowsCapability -Online -Name 'OpenSSH.Client*' -ErrorAction Stop |
    Select-Object -First 1
if (-not $capability) {
    throw 'The OpenSSH.Client Windows capability is not available on this operating system.'
}

if ($capability.State -ne 'Installed' -and $PSCmdlet.ShouldProcess('OpenSSH.Client', 'Install Windows capability')) {
    Add-WindowsCapability -Online -Name $capability.Name
}
else {
    $capability
}
