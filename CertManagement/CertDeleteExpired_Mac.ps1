<#
.SYNOPSIS
    Reports and optionally deletes expired certificates from macOS keychains.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string[]]$Keychain = @(
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Library/Keychains/login.keychain-db'),
        '/Library/Keychains/System.keychain'
    ),

    [datetime]$AsOf = (Get-Date),

    [switch]$Delete
)

if (-not $IsMacOS) {
    throw 'This script requires macOS.'
}
foreach ($command in 'security', 'openssl') {
    if (-not (Get-Command $command -CommandType Application -ErrorAction SilentlyContinue)) {
        throw "'$command' was not found in PATH."
    }
}

$results = [Collections.Generic.List[object]]::new()
foreach ($keychainPath in $Keychain) {
    if (-not (Test-Path -LiteralPath $keychainPath -PathType Leaf)) {
        Write-Warning "Keychain '$keychainPath' was not found."
        continue
    }

    $pemOutput = (& security find-certificate -a -p $keychainPath 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not read keychain '$keychainPath'."
        continue
    }

    $certificateMatches = [regex]::Matches($pemOutput, '(?s)-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----')
    foreach ($match in $certificateMatches) {
        $details = $match.Value | & openssl x509 -noout -enddate -subject -issuer -fingerprint -sha1 2>$null
        if ($LASTEXITCODE -ne 0) { continue }

        $fields = @{}
        foreach ($line in $details) {
            if ($line -match '^(?<Name>notAfter|subject|issuer|sha1 Fingerprint)=(?<Value>.*)$') {
                $fields[$Matches.Name] = $Matches.Value.Trim()
            }
        }
        $notAfter = [datetimeoffset]::MinValue
        if (-not $fields.notAfter -or -not [datetimeoffset]::TryParse(
                $fields.notAfter,
                [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::AssumeUniversal,
                [ref]$notAfter
            )) {
            continue
        }
        if ($notAfter.UtcDateTime -ge $AsOf.ToUniversalTime()) { continue }

        $thumbprint = $fields['sha1 Fingerprint'] -replace ':', ''
        $deleted = $false
        if ($Delete -and $PSCmdlet.ShouldProcess("$keychainPath :: $thumbprint", 'Delete expired certificate')) {
            & security delete-certificate -Z $thumbprint $keychainPath
            if ($LASTEXITCODE -ne 0) { throw "Failed to delete certificate '$thumbprint' from '$keychainPath'." }
            $deleted = $true
        }

        $results.Add([pscustomobject]@{
            Keychain  = $keychainPath
            Subject   = $fields.subject
            Issuer    = $fields.issuer
            Thumbprint = $thumbprint
            NotAfter  = $notAfter.LocalDateTime
            Deleted   = $deleted
        })
    }
}

$results
