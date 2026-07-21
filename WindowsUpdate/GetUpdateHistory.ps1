<#
.SYNOPSIS
    Retrieves installed Windows updates without relying on the removed WMIC utility.
#>

[CmdletBinding()]
param(
    [string[]]$ComputerName,

    [string]$OutputPath
)

$parameters = @{}
if ($ComputerName) { $parameters.ComputerName = $ComputerName }
$updates = Get-HotFix @parameters | Sort-Object InstalledOn -Descending
if ($OutputPath) {
    $updates | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8
}
$updates
