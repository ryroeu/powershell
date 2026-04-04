<#
.SYNOPSIS
    Manages active directory oud elete.
#>

# Delete OU
Remove-ADObject -Identity "OU=Finance,DC=LucernPub,DC=com" -Recursive -Confirm:$False
