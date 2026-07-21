<#
.SYNOPSIS
    Lists expired certificates from macOS keychains.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string[]]$Keychain,

    [datetime]$AsOf = (Get-Date)
)

if (-not $IsMacOS) { throw 'This script requires macOS.' }
if (-not (Get-Command security -CommandType Application -ErrorAction SilentlyContinue)) { throw "'security' was not found." }

$keychains = if ($Keychain) { $Keychain } else { @($null) }
foreach ($keychainPath in $keychains) {
    $arguments = @('find-certificate', '-a', '-p')
    if ($keychainPath) { $arguments += $keychainPath }
    $pemOutput = (& security @arguments 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Could not read keychain '$keychainPath'." }

    foreach ($certificateMatch in [regex]::Matches($pemOutput, '(?s)-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----')) {
        $certificate = $null
        try {
            $certificate = [Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPem($certificateMatch.Value)
            if ($certificate.NotAfter -lt $AsOf) {
                [pscustomobject]@{
                    Keychain   = if ($keychainPath) { $keychainPath } else { 'Default keychains' }
                    Subject    = $certificate.Subject
                    Issuer     = $certificate.Issuer
                    Thumbprint = $certificate.Thumbprint
                    NotBefore  = $certificate.NotBefore
                    NotAfter   = $certificate.NotAfter
                }
            }
        }
        finally {
            if ($certificate) { $certificate.Dispose() }
        }
    }
}
