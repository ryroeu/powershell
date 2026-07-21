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

$alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+'
$password = [securestring]::new()
for ($index = 0; $index -lt 64; $index++) {
    $password.AppendChar($alphabet[[Security.Cryptography.RandomNumberGenerator]::GetInt32($alphabet.Length)])
}
$password.MakeReadOnly()

if ($PSCmdlet.ShouldProcess($account.DistinguishedName, 'Reset KRBTGT password')) {
    $resetParameters = @{ Identity = $account.DistinguishedName; Reset = $true; NewPassword = $password }
    if ($Server) { $resetParameters.Server = $Server }
    Set-ADAccountPassword @resetParameters
    Write-Warning 'Verify replication on every domain controller before performing the second KRBTGT reset.'
}
