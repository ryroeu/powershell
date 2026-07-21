<#
.SYNOPSIS
    Lists expired certificates from Windows certificate stores.
#>

[CmdletBinding()]
param(
    [ValidateSet('CurrentUser', 'LocalMachine')]
    [string[]]$StoreLocation = @('CurrentUser', 'LocalMachine'),

    [string[]]$StoreName = @('*'),

    [datetime]$AsOf = (Get-Date)
)

if (-not $IsWindows) {
    throw 'This script requires the Windows certificate provider.'
}

foreach ($location in $StoreLocation) {
    foreach ($name in $StoreName) {
        Get-ChildItem -Path "Cert:\$location\$name" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.PSIsContainer -ne $true -and $_.NotAfter -lt $AsOf } |
            Select-Object @{ Name = 'StoreLocation'; Expression = { $location } },
            @{ Name = 'StoreName'; Expression = { $_.PSParentPath -replace '^.*Certificate::', '' } },
            Subject, Thumbprint, NotBefore, NotAfter, HasPrivateKey
    }
}
