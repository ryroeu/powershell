<#
.SYNOPSIS
    Retrieves Active Directory users and optionally exports them to CSV.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$SearchBase,

    [string]$OutputPath
)

$parameters = @{
    Filter     = '*'
    Properties = 'DisplayName', 'UserPrincipalName', 'WhenCreated', 'PasswordLastSet', 'PasswordNeverExpires', 'MemberOf', 'LastLogonDate'
}
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$users = Get-ADUser @parameters |
    Select-Object SamAccountName, DisplayName, UserPrincipalName, WhenCreated, PasswordLastSet, PasswordNeverExpires, LastLogonDate,
        @{Name = 'MemberOf'; Expression = { $_.MemberOf -join ';' } }
if ($OutputPath) { $users | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 }
$users
