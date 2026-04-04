$TargetOU = "OU=NameOfOU,DC=domain,DC=com"
$InactiveOU = "OU=Inactive Users,OU=NameOfOU,DC=domain,DC=com"
$ExpiredOU = "OU=Expired Users,OU=NameOfOU,DC=domain,DC=com"
$DisabledOU = "OU=Disabled Users,OU=NameOfOU,DC=domain,DC=com"

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

### Move Inactive Users to new OU ###
Search-ADAccount -SearchBase $TargetOU -AccountInactive -UsersOnly -TimeSpan 90.00:00:00 | Move-ADObject -TargetPath $InactiveOU

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

### Move Expired Users to new OU ###
Search-ADAccount -SearchBase $TargetOU -AccountExpired -UsersOnly | Move-ADObject -TargetPath $ExpiredOU

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

### Move Disabled Users to new OU ###
Search-ADAccount -SearchBase $TargetOU -AccountDisabled -UsersOnly | Move-ADObject -TargetPath $DisabledOU

##########################################################################