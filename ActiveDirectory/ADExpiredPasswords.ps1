<#
.SYNOPSIS
    Retrieves Active Directory users whose passwords are expired.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$SearchBase,

    [string]$OutputPath
)

$parameters = @{ UsersOnly = $true; PasswordExpired = $true }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$accounts = Search-ADAccount @parameters | Select-Object Name, SamAccountName, Enabled, PasswordExpired, PasswordNeverExpires, LastLogonDate
if ($OutputPath) { $accounts | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 }
$accounts
