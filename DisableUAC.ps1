<#
.SYNOPSIS
    Disables User Account Control on Windows.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

$path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
if ($PSCmdlet.ShouldProcess('Local computer', 'Disable UAC (requires a restart)')) {
    Set-ItemProperty -LiteralPath $path -Name EnableLUA -Value 0 -Type DWord
    Write-Warning 'UAC is disabled after the next restart. This materially reduces Windows security.'
}
