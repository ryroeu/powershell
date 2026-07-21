<#
.SYNOPSIS
    Exports directory entries to a PowerShell CLIXML file.
#>

[CmdletBinding()]
param(
    [string]$Path = $PWD,

    [string]$OutputPath = (Join-Path $PWD 'DirectoryItems.clixml'),

    [switch]$Recurse
)

Get-ChildItem -LiteralPath $Path -Recurse:$Recurse |
    Export-Clixml -LiteralPath $OutputPath -Depth 3

Get-Item -LiteralPath $OutputPath
