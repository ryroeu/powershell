### Display Disabled Accounts for OU ###
Search-ADAccount -SearchBase "OU=name,OU=name,DC=domain,DC=com" `
                 -UsersOnly `
                 -AccountDisabled