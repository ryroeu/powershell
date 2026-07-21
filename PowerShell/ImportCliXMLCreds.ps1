<#
.SYNOPSIS
    Exports or imports a credential using PowerShell CLIXML protection.
.DESCRIPTION
    On Windows, the exported credential can normally be decrypted only by the same user on the same computer.
    On non-Windows platforms, CLIXML does not provide equivalent OS-backed secrecy; protect the file permissions.
#>

[CmdletBinding(DefaultParameterSetName = 'Import')]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory, ParameterSetName = 'Export')]
    [switch]$Export,

    [Parameter(ParameterSetName = 'Export')]
    [pscredential]$Credential
)

if ($Export) {
    if (-not $Credential) {
        $Credential = Get-Credential
    }
    $Credential | Export-Clixml -LiteralPath $Path -Depth 2
    Get-Item -LiteralPath $Path
    return
}

$importedCredential = Import-Clixml -LiteralPath $Path
if ($importedCredential -isnot [pscredential]) {
    throw "'$Path' does not contain a PSCredential object."
}
$importedCredential
