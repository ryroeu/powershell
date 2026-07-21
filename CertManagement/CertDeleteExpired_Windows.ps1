<#
.SYNOPSIS
    Reports and optionally deletes expired certificates from Windows certificate stores.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string[]]$StorePath = @('Cert:\LocalMachine\My'),

    [datetime]$AsOf = (Get-Date),

    [switch]$Delete
)

if (-not $IsWindows) { throw 'This script requires Windows.' }

foreach ($path in $StorePath) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        Write-Warning "Certificate store '$path' was not found."
        continue
    }
    foreach ($certificate in Get-ChildItem -LiteralPath $path | Where-Object { -not $_.PSIsContainer -and $_.NotAfter -lt $AsOf }) {
        $deleted = $false
        if ($Delete -and $PSCmdlet.ShouldProcess("$path :: $($certificate.Thumbprint)", 'Delete expired certificate')) {
            Remove-Item -LiteralPath $certificate.PSPath -Force -ErrorAction Stop
            $deleted = $true
        }
        [pscustomobject]@{
            StorePath  = $path
            Subject    = $certificate.Subject
            Thumbprint = $certificate.Thumbprint
            NotAfter   = $certificate.NotAfter
            Deleted    = $deleted
        }
    }
}
