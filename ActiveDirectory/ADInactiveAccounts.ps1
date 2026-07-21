<#
.SYNOPSIS
    Retrieves Active Directory users inactive for a specified period.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [ValidateRange(1, 36500)]
    [int]$InactiveDays = 90,

    [string]$SearchBase,

    [string]$OutputPath
)

$parameters = @{ UsersOnly = $true; AccountInactive = $true; TimeSpan = [timespan]::FromDays($InactiveDays) }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$accounts = Search-ADAccount @parameters | Select-Object Name, SamAccountName, Enabled, LastLogonDate, DistinguishedName
if ($OutputPath) { $accounts | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 }
$accounts
