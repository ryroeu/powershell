<#
.SYNOPSIS
    Manages active directory users password expired.
#>

### Export Users with Expired Passwords to CSV ###
Search-AdAccount -UsersOnly `
                 -PasswordExpired | Select-Object -Property SAMaccountname, `
                                                            Enabled, `
                                                            PasswordExpired, `
                                                            PasswordNeverExpires, `
                                                            LastLogonDate `
                                  | Export-Csv -Path C:\ExportDir\PWExpired.csv -NoTypeInformation