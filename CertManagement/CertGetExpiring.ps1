<#
.SYNOPSIS
    Retrieves certificates that expire within a specified number of days.
#>

[CmdletBinding()]
param(
    [string[]]$StorePath = @('Cert:\CurrentUser\My'),

    [ValidateRange(0, 3650)]
    [int]$WithinDays = 90,

    [string]$OutputPath
)

$now = Get-Date
$cutoff = $now.AddDays($WithinDays)
$certificates = foreach ($path in $StorePath) {
    Get-ChildItem -LiteralPath $path -Recurse |
        Where-Object { -not $_.PSIsContainer -and $_.NotAfter -ge $now -and $_.NotAfter -le $cutoff } |
        Select-Object @{Name = 'StorePath'; Expression = { $path } }, Subject, Issuer, Thumbprint, NotBefore, NotAfter
}
$certificates = $certificates | Sort-Object NotAfter
if ($OutputPath) { $certificates | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 }
$certificates
