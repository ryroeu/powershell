<#
.SYNOPSIS
    Resets the Active Directory KRBTGT account to a cryptographically random password.
.DESCRIPTION
    A complete KRBTGT rotation normally requires two resets after replication has completed between them.
    Run this script once per reset and verify domain-controller replication before the second run.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$Server
)

$parameters = @{ Identity = 'krbtgt'; Properties = 'DistinguishedName' }
if ($Server) { $parameters.Server = $Server }
$account = Get-ADUser @parameters

$characterSets = @(
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'abcdefghijklmnopqrstuvwxyz',
    '0123456789',
    '!@#$%^&*()-_=+'
)
$characters = [Collections.Generic.List[char]]::new()
foreach ($characterSet in $characterSets) {
    $characters.Add($characterSet[[Security.Cryptography.RandomNumberGenerator]::GetInt32($characterSet.Length)])
}
$alphabet = $characterSets -join ''
while ($characters.Count -lt 64) {
    $characters.Add($alphabet[[Security.Cryptography.RandomNumberGenerator]::GetInt32($alphabet.Length)])
}
$characters = $characters | Sort-Object { [Security.Cryptography.RandomNumberGenerator]::GetInt32([int]::MaxValue) }
$password = [securestring]::new()
foreach ($character in $characters) {
    $password.AppendChar($character)
}
$password.MakeReadOnly()

if ($PSCmdlet.ShouldProcess($account.DistinguishedName, 'Reset KRBTGT password')) {
    $resetParameters = @{ Identity = $account.DistinguishedName; Reset = $true; NewPassword = $password }
    if ($Server) { $resetParameters.Server = $Server }
    Set-ADAccountPassword @resetParameters
    Write-Warning 'Verify replication on every domain controller before performing the second KRBTGT reset.'
}
