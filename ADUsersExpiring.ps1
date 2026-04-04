<#
.SYNOPSIS
    Manages active directory users expiring.
#>

### Export Users with Expiring Status to CSV ###
Search-ADAccount -UsersOnly `
                 -AccountExpiring | Select-Object -Property SAMaccountname, `
                                                                       Enabled, `
                                                                       PasswordExpired, `
                                                                       PasswordNeverExpires, `
                                                                       LastLogonDate `
                                  | Export-Csv C:\ExportDir\ExpiringUsers.csv -NoTypeInformation