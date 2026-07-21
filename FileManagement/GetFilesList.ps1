<#
.SYNOPSIS
    Exports a sorted file inventory to CSV.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [string]$OutputPath = (Join-Path $PWD 'Files.csv'),

    [switch]$Recurse
)

Get-ChildItem -LiteralPath $Path -File -Recurse:$Recurse |
    Select-Object Name, FullName, Length, CreationTimeUtc, LastWriteTimeUtc |
    Sort-Object FullName |
    Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8
