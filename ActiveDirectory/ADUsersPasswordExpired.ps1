<#
.SYNOPSIS
    Retrieves Active Directory users with expired passwords.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$SearchBase,

    [string]$OutputPath
)

$parameters = @{ UsersOnly = $true; PasswordExpired = $true }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$users = Search-ADAccount @parameters |
    Select-Object SamAccountName, Enabled, PasswordExpired, PasswordNeverExpires, LastLogonDate, DistinguishedName
if ($OutputPath) { $users | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 }
$users
