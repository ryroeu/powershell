<#
.SYNOPSIS
    Retrieves SharePoint users.
#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA SilentlyContinue

#Parameter
$URL="https://sharepoint.company.com/sites/csaportal"
$CSVFile = "C:\Temp\UsersandGroupsRpt.txt"

#Get the Site
$Site = Get-SPSite $URL

#Write the Header to "Tab Separated Text File"
"Site Name `t  URL `t Group Name `t User Account `t User Name `t E-Mail" | Out-File $CSVFile

#Iterate through all Webs
ForEach ($Web in $Site.AllWebs) {
    #Write the Header to "Tab Separated Text File"
    "$($Web.Title) `t $($Web.URL) `t  `t  `t `t " | Out-File $CSVFile -append
    #Get all Groups and Iterate through
    foreach ($group in $Web.Groups) {
        "`t  `t $($Group.Name) `t `t `t " | Out-File $CSVFile -append
        #Iterate through Each User in the group
        foreach ($user in $group.Users) {
            #Exclude Built-in User Accounts
            if (($User.LoginName.ToLower() -ne "NT Authority\Authenticated Users") -and ($User.LoginName.ToLower() -ne "Sharepoint\System") -and ($User.LoginName.ToLower() -ne "NT Authority\Local Service")) {
                "`t  `t  `t  $($user.LoginName)  `t  $($user.Name) `t  $($user.Email)" | Out-File $CSVFile -Append
            }
        }
    }
}
Write-Host "Report Generated at $CSVFile"
