<#
.SYNOPSIS
    Exports certificate inventory to CSV.
#>

[CmdletBinding()]
param(
    [string[]]$StorePath = @('Cert:\CurrentUser', 'Cert:\LocalMachine'),

    [string]$OutputPath = (Join-Path $PWD 'Certificates.csv')
)

$certificates = foreach ($path in $StorePath) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    Get-ChildItem -LiteralPath $path -Recurse |
        Where-Object { -not $_.PSIsContainer } |
        Select-Object @{Name = 'StorePath'; Expression = { $path } }, Subject, Issuer, Thumbprint, NotBefore, NotAfter, HasPrivateKey
}
$certificates | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8
Get-Item -LiteralPath $OutputPath
