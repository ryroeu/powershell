<#
.SYNOPSIS
    Creates an alias for Server Manager in the current scope.
.DESCRIPTION
    Dot-source this script to retain the alias in the caller's session.
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$Name = 'sm',

    [string]$Value = "$env:SystemRoot\System32\ServerManager.exe",

    [switch]$Force
)

if (-not (Test-Path -LiteralPath $Value -PathType Leaf)) {
    throw "Server Manager was not found at '$Value'."
}

Set-Alias -Name $Name -Value $Value -Scope Script -Force:$Force
Get-Alias -Name $Name
