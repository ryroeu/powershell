<#
.SYNOPSIS
    Removes Active Directory users.
#>

$TargetOU = "OU=NameOfOU,DC=domain,DC=com"

##########################################################################
### Export Inactive Users to CSV for Reference ###
Search-ADAccount -SearchBase $TargetOU `
                 -AccountInactive `
                 -UsersOnly `
                 -TimeSpan 90.00:00:00 | Select-Object -Property SAMaccountname, `
                                                                 Enabled, `
                                                                 PasswordExpired, `
                                                                 PasswordNeverExpires, `
                                                                 LastLogonDate `
                                       | Export-Csv C:\ExportDir\InactiveUsers.csv -NoTypeInformation

### Remove Inactive Users ###
Search-ADAccount -SearchBase $TargetOU -AccountInactive -UsersOnly -TimeSpan 90.00:00:00 | Remove-ADUser

##########################################################################
### Export Expired Users to CSV for Reference ###
Search-ADAccount -SearchBase $TargetOU `
                 -AccountExpired `
                 -UsersOnly | Select-Object -Property SAMaccountname, `
                                                      Enabled, `
                                                      PasswordExpired, `
                                                      PasswordNeverExpires, `
                                                      LastLogonDate `
                            | Export-Csv C:\ExportDir\ExpiredUsers.csv -NoTypeInformation

### Remove Expired Users ###
Search-ADAccount -SearchBase $TargetOU -AccountExpired -UsersOnly | Remove-ADUser

##########################################################################
### Export Disabled Users to CSV for Reference ###
Search-ADAccount -SearchBase $TargetOU `
                 -AccountDisabled `
                 -UsersOnly | Select-Object -Property SAMaccountname, `
                                                      Enabled, `
                                                      PasswordExpired, `
                                                      PasswordNeverExpires, `
                                                      LastLogonDate `
                            | Export-Csv C:\ExportDir\DisabledUsers.csv -NoTypeInformation

### Remove Disabled Users ###
Search-ADAccount -SearchBase $TargetOU -AccountDisabled -UsersOnly | Remove-ADUser

##########################################################################