<#
.SYNOPSIS
    Retrieves Active Directory users.
#>

### GET ALL USER ACCOUNTS ###
Get-ADuser -Filter * -Properties SamAccountName,DisplayName,UserPrincipalName,whenCreated,PasswordLastSet,PasswordNeverExpires,MemberOf,LastLogonDate `
			| Export-csv .\AllUsers.csv -NoTypeInformation -UseCulture