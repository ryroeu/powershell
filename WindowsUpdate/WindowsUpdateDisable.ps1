<#
.SYNOPSIS
    Disables automatic Windows Update checks through policy.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [switch]$StopServices
)

if (-not $IsWindows) { throw 'This script requires Windows.' }
$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'

if ($PSCmdlet.ShouldProcess($policyPath, 'Set NoAutoUpdate policy to 1')) {
    New-Item -Path $policyPath -Force | Out-Null
    New-ItemProperty -Path $policyPath -Name NoAutoUpdate -PropertyType DWord -Value 1 -Force | Out-Null
}

if ($StopServices) {
    foreach ($serviceName in 'wuauserv', 'BITS') {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne 'Stopped' -and $PSCmdlet.ShouldProcess($serviceName, 'Stop service')) {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
        }
    }
}

Write-Warning 'Automatic updates are disabled by local policy. Re-enable them promptly to continue receiving security fixes.'
