<#
.SYNOPSIS
    Reports accounts whose passwords never expire and can clear that setting.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$SearchBase,

    [string]$ExportPath,

    [switch]$DisableNeverExpire
)

$parameters = @{ PasswordNeverExpires = $true; UsersOnly = $true; ErrorAction = 'Stop' }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$users = @(Search-ADAccount @parameters |
        Get-ADUser -Properties PasswordExpired, PasswordNeverExpires, LastLogonDate)

$report = $users | Select-Object SamAccountName, Name, DistinguishedName, Enabled, PasswordExpired, PasswordNeverExpires, LastLogonDate
if ($ExportPath) {
    $directory = Split-Path -Path $ExportPath -Parent
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $report | Export-Csv -LiteralPath $ExportPath -NoTypeInformation -Encoding utf8NoBOM
}

if ($DisableNeverExpire) {
    foreach ($user in $users) {
        if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Disable Password Never Expires')) {
            Set-ADUser -Identity $user -PasswordNeverExpires $false -ErrorAction Stop
        }
    }
}

$report
