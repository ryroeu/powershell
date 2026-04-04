#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$TrustedHosts,

    [switch]$EnableCredSSP,

    [string[]]$DelegateComputer,

    [ValidateSet('DoNotChange', 'RemoteSigned', 'AllSigned', 'Bypass')]
    [string]$ExecutionPolicy = 'DoNotChange'
)

if ($PSCmdlet.ShouldProcess('WinRM', 'Enable PowerShell remoting on this client')) {
    Set-WSManQuickConfig -Force | Out-Null
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
}

if ($TrustedHosts) {
    $trustedHostsValue = $TrustedHosts -join ','
    if ($PSCmdlet.ShouldProcess('WSMan TrustedHosts', ('Set trusted hosts to {0}' -f $trustedHostsValue))) {
        Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $trustedHostsValue -Force
        Restart-Service -Name WinRM
    }
}

if ($EnableCredSSP) {
    if (-not $DelegateComputer) {
        throw 'Provide -DelegateComputer when using -EnableCredSSP.'
    }

    if ($PSCmdlet.ShouldProcess('CredSSP client role', ('Enable CredSSP for {0}' -f ($DelegateComputer -join ', ')))) {
        Enable-WSManCredSSP -Role Client -DelegateComputer $DelegateComputer -Force
    }
}

if ($ExecutionPolicy -ne 'DoNotChange' -and $PSCmdlet.ShouldProcess('Execution Policy', ('Set LocalMachine execution policy to {0}' -f $ExecutionPolicy))) {
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy $ExecutionPolicy -Force
}
