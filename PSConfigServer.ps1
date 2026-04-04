#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$EnableCredSSP,

    [ValidateSet('DoNotChange', 'RemoteSigned', 'AllSigned', 'Bypass')]
    [string]$ExecutionPolicy = 'DoNotChange'
)

if ($PSCmdlet.ShouldProcess('WinRM', 'Enable PowerShell remoting on this server')) {
    Set-WSManQuickConfig -Force | Out-Null
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
}

if ($EnableCredSSP -and $PSCmdlet.ShouldProcess('CredSSP server role', 'Enable CredSSP on this server')) {
    Enable-WSManCredSSP -Role Server -Force
}

if ($ExecutionPolicy -ne 'DoNotChange' -and $PSCmdlet.ShouldProcess('Execution Policy', ('Set LocalMachine execution policy to {0}' -f $ExecutionPolicy))) {
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy $ExecutionPolicy -Force
}
