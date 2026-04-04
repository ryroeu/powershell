<#
.SYNOPSIS
    Resets Active Directory KRBTGT.
#>

# To reset the password for the KRBTGT account, sign into a domain controller with a user account that is a member of the Domain Admins group.
Set-ADAccountPassword -Identity (Get-ADUser krbtgt).DistinguishedName -Reset -NewPassword (ConvertTo-SecureString "Rand0mCompl3xP@ssw0rd!" -AsPlainText -Force)
