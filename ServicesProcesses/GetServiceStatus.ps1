<#
.SYNOPSIS
    Retrieves service status information.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('ServiceName')]
    [string[]]$Name,

    [string]$ComputerName
)

process {
    $parameters = @{ Name = $Name }
    if ($ComputerName) {
        $parameters.ComputerName = $ComputerName
    }
    Get-Service @parameters | Select-Object Name, DisplayName, Status, StartType, MachineName
}
