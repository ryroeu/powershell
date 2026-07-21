<#
.SYNOPSIS
    Selects rows from one CSV whose key exists in a second CSV.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$PrimaryPath,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$LookupPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$KeyProperty,

    [string]$OutputPath,

    [switch]$CaseSensitive,

    [switch]$ExcludeMatches
)

$primaryData = @(Import-Csv -LiteralPath $PrimaryPath)
$lookupData = @(Import-Csv -LiteralPath $LookupPath)
foreach ($csvInput in @(
        @{ Name = 'primary'; Rows = $primaryData; Path = $PrimaryPath },
        @{ Name = 'lookup'; Rows = $lookupData; Path = $LookupPath }
    )) {
    if ($csvInput.Rows -and $csvInput.Rows[0].PSObject.Properties.Name -notcontains $KeyProperty) {
        throw "Column '$KeyProperty' was not found in $($csvInput.Name) CSV '$($csvInput.Path)'."
    }
}

$comparer = if ($CaseSensitive) { [StringComparer]::Ordinal } else { [StringComparer]::OrdinalIgnoreCase }
$lookupKeys = [Collections.Generic.HashSet[string]]::new($comparer)
foreach ($row in $lookupData) {
    if ($null -ne $row.$KeyProperty) { [void]$lookupKeys.Add([string]$row.$KeyProperty) }
}

$results = @($primaryData | Where-Object {
        $matched = $lookupKeys.Contains([string]$_.$KeyProperty)
        if ($ExcludeMatches) { -not $matched } else { $matched }
    })
if ($OutputPath) {
    $results | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8NoBOM
}
$results
