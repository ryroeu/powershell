<#
.SYNOPSIS
    Updates Active Directory home folder.
#>

$Usernames = Get-ADUser -Filter * | Format-Table SamAccountName
foreach ($Username in $Usernames){
    Set-ADUser $Username -HomeDirectory \\CEBU-SRV2\USERS\$Username -HomeDrive Z:
}