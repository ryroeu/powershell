#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Manages powershell config server.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [switch]$EnableCredSSP,

    [ValidateSet('DoNotChange', 'RemoteSigned', 'AllSigned', 'Bypass')]
    [string]$ExecutionPolicy = 'DoNotChange'
)

if (-not $IsWindows) { throw 'This script requires Windows.' }

if ($PSCmdlet.ShouldProcess('WinRM', 'Enable PowerShell remoting on this server')) {
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
}

if ($EnableCredSSP -and $PSCmdlet.ShouldProcess('CredSSP server role', 'Enable CredSSP on this server')) {
    Enable-WSManCredSSP -Role Server -Force
}

if ($ExecutionPolicy -ne 'DoNotChange' -and $PSCmdlet.ShouldProcess('Execution Policy', ('Set LocalMachine execution policy to {0}' -f $ExecutionPolicy))) {
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy $ExecutionPolicy -Force
}
