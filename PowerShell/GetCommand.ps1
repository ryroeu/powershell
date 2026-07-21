<#
.SYNOPSIS
    Exports command metadata for one or more installed modules.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$Module,

    [string]$OutputDirectory = $PWD
)

$null = New-Item -ItemType Directory -Path $OutputDirectory -Force
foreach ($moduleName in $Module) {
    $safeName = $moduleName -replace '[^A-Za-z0-9_.-]', '_'
    $outputPath = Join-Path $OutputDirectory "$safeName.csv"
    Get-Command -Module $moduleName -ErrorAction Stop |
        Select-Object Name, ModuleName, Version, Visibility, CommandType, Definition |
        Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding utf8
    Get-Item -LiteralPath $outputPath
}
