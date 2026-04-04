<#
.SYNOPSIS
    Manages active directory inactive accounts.
#>

### SEARCH 90 DAY INACTIVE ACCOUNTS BY USERS ONLY ###
Search-ADAccount -UsersOnly `
                 -AccountInactive `
                 -TimeSpan 90.00:00:00 | Export-Csv C:\ExportDir\InactiveAccounts.csv -NoTypeInformation


### SEARCH 90 DAY INACTIVE ACCOUNTS BY OU ###
Search-ADAccount -SearchBase "OU=name,OU=name,DC=domain,DC=com" `
                 -UsersOnly `
                 -AccountInactive `
                 -TimeSpan 90.00:00:00 | Export-Csv C:\ExportDir\InactiveAccounts.csv -NoTypeInformation