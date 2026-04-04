<#
.SYNOPSIS
    Manages active directory deleted objects.
#>

# To view the deleted objects for a domain, use the following lines of PowerShell on a system with the Active Directory Module for Windows PowerShell installed:
Get-ADObject -ldapFilter:"(msDS-LastKnownRDN=*)" -IncludeDeletedObjects

# To restore a deleted object, use the following lines of PowerShell on a system with the Active Directory Windows PowerShell Module installed:
Get-ADObject -Filter {displayName -eq "DisplayNameOfTheObject"} -IncludeDeletedObjects | Restore-ADObject
