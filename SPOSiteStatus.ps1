#Change your tenant admin account below
$username = "admin@domain.com"
$password = read-host "password" -AsSecureString
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $password
#
#Must be SharePoint Admin URL
$siteUrl = "https://domain.sharepoint.com"
#
Import-Module -Name Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
Connect-SPOService -Url $siteUrl -Credential $cred
#
Write-Host "1. List all NoAccess Site Collections" -ForegroundColor Green
Write-Host "2. List all ReadOnly Site Collections" -ForegroundColor Magenta
Write-Host "3. Set Site Collection to NoAccess" -ForegroundColor Cyan
Write-Host "4. Set Site Collection to ReadOnly" -ForegroundColor Yellow
Write-Host "5. Unlock site collection" -ForegroundColor Red
$choice = Read-Host "Choice [1-5]?"
#
switch ($choice) {
    1 { Get-SPOSite -Filter {LockState -eq "NoAccess"} }
    2 { Get-SPOSite -Filter {LockState -eq "ReadOnly"} }
    3 { $site = Read-Host "The site collection you want to set NoAccess"
    Set-SPOSite -Identity $site -LockState "NoAccess" }
    4 { $site = Read-Host "The site collection you want to set ReadOnly"
    Set-SPOSite -Identity $site -LockState "ReadOnly" }
    5 { $site = Read-Host "The site collection you want to UnLock"
    Set-SPOSite -Identity $site -LockState "UnLock"}
    default {":-) You must be kidding."}
}
