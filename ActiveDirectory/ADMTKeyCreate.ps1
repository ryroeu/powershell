<#
.SYNOPSIS
    Creates an ADMT Password Export Server encryption key.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$SourceDomain,

    [Parameter(Mandatory)]
    [string]$KeyFile,

    [Parameter(Mandatory)]
    [securestring]$KeyPassword,

    [string]$AdmtPath = 'ADMT.exe'
)

$admt = Get-Command $AdmtPath -ErrorAction Stop
$plainPassword = [Net.NetworkCredential]::new('', $KeyPassword).Password
try {
    if ($PSCmdlet.ShouldProcess($KeyFile, "Create ADMT key for '$SourceDomain'")) {
        & $admt.Source key /Option:Create "/SourceDomain:$SourceDomain" "/KeyFile:$KeyFile" "/KeyPassword:$plainPassword"
        if ($LASTEXITCODE -ne 0) { throw "ADMT key creation failed with exit code $LASTEXITCODE." }
        Get-Item -LiteralPath $KeyFile
    }
}
finally {
    $plainPassword = $null
}
