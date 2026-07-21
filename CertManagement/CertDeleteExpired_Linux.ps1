<#
.SYNOPSIS
    Reports and optionally deletes expired certificate files on Linux.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string[]]$SearchPath,

    [string[]]$Extension = @('.pem', '.crt', '.cer'),

    [datetime]$AsOf = (Get-Date),

    [switch]$Delete
)

if (-not $IsLinux) { throw 'This script requires Linux.' }
if (-not (Get-Command openssl -CommandType Application -ErrorAction SilentlyContinue)) { throw "'openssl' was not found." }

foreach ($directory in $SearchPath) {
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        Write-Warning "Directory '$directory' was not found."
        continue
    }
    foreach ($file in Get-ChildItem -LiteralPath $directory -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object Extension -In $Extension) {
        $output = & openssl x509 -in $file.FullName -noout -enddate 2>$null
        if ($LASTEXITCODE -ne 0 -or $output -notmatch '^notAfter=(?<Date>.+)$') { continue }

        $notAfter = [datetimeoffset]::MinValue
        if (-not [datetimeoffset]::TryParse(
                $Matches.Date,
                [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::AssumeUniversal,
                [ref]$notAfter
            )) { continue }
        if ($notAfter.UtcDateTime -ge $AsOf.ToUniversalTime()) { continue }

        $deleted = $false
        if ($Delete -and $PSCmdlet.ShouldProcess($file.FullName, 'Delete expired certificate file')) {
            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
            $deleted = $true
        }
        [pscustomobject]@{ FilePath = $file.FullName; NotAfter = $notAfter.LocalDateTime; Deleted = $deleted }
    }
}
