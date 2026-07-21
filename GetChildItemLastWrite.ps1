<#
.SYNOPSIS
    Returns items modified after a specified date and time.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [datetime]$LastWrite,

    [string]$Path = $PWD,

    [switch]$Recurse
)

Get-ChildItem -LiteralPath $Path -Recurse:$Recurse |
    Where-Object LastWriteTime -gt $LastWrite
