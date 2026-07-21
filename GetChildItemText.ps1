<#
.SYNOPSIS
    Writes a directory listing to a UTF-8 text file.
#>

[CmdletBinding()]
param(
    [string]$Path = $PWD,

    [string]$OutputPath = (Join-Path $PWD 'DirectoryItems.txt'),

    [switch]$Recurse
)

Get-ChildItem -LiteralPath $Path -Recurse:$Recurse |
    Select-Object Mode, LastWriteTime, Length, FullName |
    Format-Table -AutoSize |
    Out-File -LiteralPath $OutputPath -Encoding utf8
Get-Item -LiteralPath $OutputPath
