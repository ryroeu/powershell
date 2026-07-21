<#
.SYNOPSIS
    Runs PSScriptAnalyzer with this repository's settings.
#>

[CmdletBinding()]
param(
    [string]$Path = $PSScriptRoot,

    [string]$Settings = (Join-Path $PSScriptRoot 'PSScriptAnalyzerSettings.psd1'),

    [switch]$NoRecurse
)

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    throw 'PSScriptAnalyzer is not installed. Run Install-PSResource PSScriptAnalyzer -Scope CurrentUser.'
}

Import-Module PSScriptAnalyzer -ErrorAction Stop
$parameters = @{ Path = $Path; Recurse = -not $NoRecurse }
if (Test-Path -LiteralPath $Settings) {
    $parameters.Settings = $Settings
}

$results = @(Invoke-ScriptAnalyzer @parameters)
$results
if ($results.Where({ $_.Severity -in 'Error', 'Warning' }).Count -gt 0) {
    $host.SetShouldExit(1)
}
