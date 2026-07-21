<#
.SYNOPSIS
    Retrieves a Windows registry key or named value.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [string]$Name
)

if ($Name) {
    Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop |
        Select-Object -ExpandProperty $Name
}
else {
    Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
}
