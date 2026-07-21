<#
.SYNOPSIS
    Stops processes by name or process ID.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Name')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Name')]
    [string[]]$Name,

    [Parameter(Mandatory, ParameterSetName = 'Id')]
    [int[]]$Id,

    [switch]$Force
)

$processes = if ($PSCmdlet.ParameterSetName -eq 'Id') {
    Get-Process -Id $Id -ErrorAction Stop
}
else {
    Get-Process -Name $Name -ErrorAction Stop
}

foreach ($process in $processes) {
    if ($PSCmdlet.ShouldProcess("$($process.ProcessName) ($($process.Id))", 'Stop process')) {
        $process | Stop-Process -Force:$Force
    }
}
