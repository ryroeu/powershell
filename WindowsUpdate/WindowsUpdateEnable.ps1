<#
.SYNOPSIS
    Re-enables automatic Windows Update checks and restores core services to demand start.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [switch]$StartScan
)

if (-not $IsWindows) { throw 'This script requires Windows.' }
$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'

if ((Test-Path -LiteralPath $policyPath) -and
    $PSCmdlet.ShouldProcess("$policyPath :: NoAutoUpdate", 'Remove policy value')) {
    Remove-ItemProperty -Path $policyPath -Name NoAutoUpdate -ErrorAction SilentlyContinue
}

foreach ($serviceName in 'wuauserv', 'BITS') {
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($serviceName, 'Set service startup type to Manual')) {
            Set-Service -Name $serviceName -StartupType Manual -ErrorAction Stop
        }
    }
}

if ($StartScan) {
    if (-not (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue)) {
        throw 'Install/import the PSWindowsUpdate module before using -StartScan.'
    }
    Get-WindowsUpdate
}
