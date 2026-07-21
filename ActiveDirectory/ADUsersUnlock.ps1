<#
.SYNOPSIS
    Reports locked Active Directory accounts and optionally unlocks them.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$SearchBase,

    [string]$ExportPath,

    [switch]$Unlock
)

$parameters = @{ UsersOnly = $true; LockedOut = $true; ErrorAction = 'Stop' }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$users = @(Search-ADAccount @parameters |
        Get-ADUser -Properties LockedOut, PasswordExpired, PasswordNeverExpires, LastLogonDate)
$report = $users | Select-Object SamAccountName, Enabled, LockedOut, PasswordExpired, PasswordNeverExpires, LastLogonDate, DistinguishedName

if ($ExportPath) {
    $directory = Split-Path -Path $ExportPath -Parent
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    $report | Export-Csv -LiteralPath $ExportPath -NoTypeInformation -Encoding utf8NoBOM
}

if ($Unlock) {
    foreach ($user in $users) {
        if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Unlock Active Directory account')) {
            Unlock-ADAccount -Identity $user -ErrorAction Stop
        }
    }
}

$report
