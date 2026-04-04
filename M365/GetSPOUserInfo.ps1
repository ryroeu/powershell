<#
.SYNOPSIS
    Retrieves SharePoint Online user information.
#>

Export-SPOUserInfo -LoginName joe.healy@contoso.com -site https://contoso.sharepoint.com/sites/sc1 -OutputFolder "C:\users\admin\exportfolder"