<#
.SYNOPSIS
    Retrieves currently locked Active Directory user accounts.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$SearchBase
)

$parameters = @{ UsersOnly = $true; LockedOut = $true }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
Search-ADAccount @parameters |
    Select-Object Name, SamAccountName, LockedOut, LastLogonDate, DistinguishedName
