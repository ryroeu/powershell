<#
.SYNOPSIS
    Finds expired PEM or DER certificate files on Linux.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string[]]$Path = @(
        '/etc/ssl/certs',
        '/etc/pki/tls/certs',
        '/etc/pki/ca-trust/extracted/pem',
        '/usr/local/share/ca-certificates',
        '/usr/share/ca-certificates'
    ),

    [string[]]$Extension = @('.crt', '.pem', '.cer'),

    [datetime]$AsOf = (Get-Date)
)

if (-not $IsLinux) {
    throw 'This script requires Linux.'
}
if (-not (Get-Command openssl -CommandType Application -ErrorAction SilentlyContinue)) {
    throw 'OpenSSL was not found in PATH.'
}

$files = foreach ($directory in $Path) {
    if (Test-Path -LiteralPath $directory -PathType Container) {
        Get-ChildItem -LiteralPath $directory -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object Extension -in $Extension
    }
}

foreach ($file in $files | Sort-Object FullName -Unique) {
    $output = & openssl x509 -in $file.FullName -noout -enddate -subject -issuer -serial 2>$null
    if ($LASTEXITCODE -ne 0) { continue }

    $fields = @{}
    foreach ($line in $output) {
        if ($line -match '^(?<Name>notAfter|subject|issuer|serial)=(?<Value>.*)$') {
            $fields[$Matches.Name] = $Matches.Value.Trim()
        }
    }
    if (-not $fields.notAfter) { continue }

    $notAfter = [datetimeoffset]::MinValue
    if (-not [datetimeoffset]::TryParse(
            $fields.notAfter,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal,
            [ref]$notAfter
        )) {
        Write-Warning "Could not parse expiration date '$($fields.notAfter)' in '$($file.FullName)'."
        continue
    }

    if ($notAfter.UtcDateTime -lt $AsOf.ToUniversalTime()) {
        [pscustomobject]@{
            Subject  = $fields.subject
            Issuer   = $fields.issuer
            Serial   = $fields.serial
            NotAfter = $notAfter.LocalDateTime
            FilePath = $file.FullName
        }
    }
}
