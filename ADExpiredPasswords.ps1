<#
.SYNOPSIS
    Manages active directory expired passwords.
#>

### Display Users who have been inactive 90 Days ###
$InactiveDays = 90
$MaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
Search-AdAccount -PasswordExpired `
                 -UsersOnly | Where-Object {((Get-Date) - (Get-AdUser -Filter "samAccountName -eq $_.SamAccountName").PasswordLastSet) -lt ($MaxPasswordAge + $InactiveDays)}
Read-Host -Prompt "Press Enter to exit"