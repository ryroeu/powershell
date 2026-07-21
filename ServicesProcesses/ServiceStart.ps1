<#
.SYNOPSIS
    Starts a Windows service and waits for it to reach the Running state.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 60
)

$service = Get-Service -Name $Name -ErrorAction Stop
if ($service.Status -ne 'Running' -and $PSCmdlet.ShouldProcess($service.Name, 'Start service')) {
    Start-Service -InputObject $service -ErrorAction Stop
    $service.WaitForStatus('Running', [timespan]::FromSeconds($TimeoutSeconds))
    $service.Refresh()
}

$service
