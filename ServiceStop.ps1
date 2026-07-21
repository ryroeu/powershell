<#
.SYNOPSIS
    Stops a Windows service and waits for it to reach the Stopped state.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 60,

    [switch]$Force
)

$service = Get-Service -Name $Name -ErrorAction Stop
if ($service.Status -ne 'Stopped' -and $PSCmdlet.ShouldProcess($service.Name, 'Stop service')) {
    Stop-Service -InputObject $service -Force:$Force -ErrorAction Stop
    $service.WaitForStatus('Stopped', [timespan]::FromSeconds($TimeoutSeconds))
    $service.Refresh()
}

$service
