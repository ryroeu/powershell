<#
.SYNOPSIS
    Retrieves SharePoint group members.
#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA SilentlyContinue

$URL="https://sharepoint.company.com/sites/helpdesk/us"
$Site = Get-SPSite $URL

If(Get-SPWeb($url).HasUniqueRoleAssignments -eq $true) {
    $Web=Get-SPWeb($url)
}
else {
    $web= $site.RootWeb
}

#Get all Groups and Iterate through
ForEach ($Group in $Web.SiteGroups) {
    Write-Host " Group Name: "$Group.Name "`n---------------------------`n"
    #Iterate through Each User in the group
    foreach ($User in $Group.Users) {
        Write-Host $User.Name  "`t" $User.LoginName  "`t"  $User.Email  | Format-Table
    }
    Write-Host "=================================="  #Group Separator
}
