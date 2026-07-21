<#
.SYNOPSIS
    Reports or stops an explicit list of non-default Windows services.
.DESCRIPTION
    Automatic classification of a service as safe to stop is unreliable. This version requires
    callers to supply the exact service names and performs no changes unless -Stop is specified.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string[]]$Name,

    [switch]$Stop,

    [switch]$Force,

    [ValidateRange(1, 600)]
    [int]$TimeoutSeconds = 90
)

if (-not $IsWindows) { throw 'This script requires Windows.' }

$protectedServices = @('RpcSs', 'DcomLaunch', 'LSM', 'PlugPlay', 'Power', 'Wininit', 'Winlogon')
$services = foreach ($serviceName in $Name | Sort-Object -Unique) {
    if ($serviceName -in $protectedServices) {
        throw "Refusing to stop protected service '$serviceName'."
    }
    Get-Service -Name $serviceName -ErrorAction Stop
}

if ($Stop) {
    foreach ($service in $services | Where-Object Status -NE 'Stopped') {
        if ($PSCmdlet.ShouldProcess($service.Name, 'Stop Windows service')) {
            Stop-Service -Name $service.Name -Force:$Force -ErrorAction Stop
            $service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Stopped, [timespan]::FromSeconds($TimeoutSeconds))
        }
    }
}

$services | ForEach-Object { Get-Service -Name $_.Name } |
    Select-Object Name, DisplayName, Status, StartType
