<#
.SYNOPSIS
    Manages cert get expiring.
#>

# Get certificates that are about to expire
Get-ChildItem -Path cert: -Recurse | Where-Object NotAfter -LE (Get-Date).AddDays(90) `
    | Select-Object Subject, Issuer, Thumbprint, NotBefore, NotAfter `
    | Sort-Object NotAfter `
    | Export-Csv CertsExpiring90.csv