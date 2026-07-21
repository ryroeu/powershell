<#
.SYNOPSIS
    Creates a Hyper-V checkpoint.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$VMName,

    [string]$SnapshotName = ('Manual checkpoint {0:yyyy-MM-dd HHmmss}' -f (Get-Date)),

    [string]$ComputerName
)

$parameters = @{ VMName = $VMName; SnapshotName = $SnapshotName }
if ($ComputerName) { $parameters.ComputerName = $ComputerName }

if ($PSCmdlet.ShouldProcess(($ComputerName ?? $env:COMPUTERNAME), "Checkpoint VM '$VMName' as '$SnapshotName'")) {
    Checkpoint-VM @parameters
}
