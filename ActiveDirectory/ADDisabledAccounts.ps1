<#
.SYNOPSIS
    Retrieves disabled Active Directory user accounts.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$SearchBase,

    [string]$OutputPath
)

$parameters = @{ UsersOnly = $true; AccountDisabled = $true }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$accounts = Search-ADAccount @parameters | Select-Object Name, SamAccountName, DistinguishedName, LastLogonDate
if ($OutputPath) { $accounts | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 }
$accounts
