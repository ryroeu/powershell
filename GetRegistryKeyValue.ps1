<#
.SYNOPSIS
    Tests whether a registry value equals an expected value.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [object]$ExpectedValue
)

$property = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
$actualValue = if ($property) { $property.$Name } else { $null }

[pscustomobject]@{
    Path          = $Path
    Name          = $Name
    ExpectedValue = $ExpectedValue
    ActualValue   = $actualValue
    Matches       = $null -ne $property -and $actualValue -eq $ExpectedValue
}
