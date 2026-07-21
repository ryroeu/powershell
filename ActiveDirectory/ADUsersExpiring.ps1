<#
.SYNOPSIS
    Retrieves Active Directory users whose accounts are expiring.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [timespan]$TimeSpan,

    [string]$SearchBase,

    [string]$OutputPath
)

$parameters = @{ UsersOnly = $true; AccountExpiring = $true }
if ($TimeSpan) { $parameters.TimeSpan = $TimeSpan }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$accounts = Search-ADAccount @parameters | Select-Object SamAccountName, Enabled, AccountExpirationDate, LastLogonDate, DistinguishedName
if ($OutputPath) { $accounts | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 }
$accounts
