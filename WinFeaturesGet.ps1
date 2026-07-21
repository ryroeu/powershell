<#
.SYNOPSIS
    Retrieves Windows Server feature status and optionally exports it to CSV.
#>

[CmdletBinding()]
param(
    [string[]]$Name = '*',

    [string]$ComputerName,

    [string]$OutputPath
)

$parameters = @{ Name = $Name }
if ($ComputerName) {
    $parameters.ComputerName = $ComputerName
}
$features = Get-WindowsFeature @parameters |
    Select-Object Name, DisplayName, Installed, InstallState, FeatureType

if ($OutputPath) {
    $features | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8
}
$features
