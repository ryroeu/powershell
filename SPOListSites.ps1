Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
#
$AdminUrl = "https://domain.sharepoint.com/"
$UserName = "admin@domain.com"
$Password = "password"
$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
$SPOCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
#
function Get-SPOWeb(){
param(
   $Url = $(throw "Please provide a Site Collection Url"),
   [SecureString] $Credential = $(throw "Please provide a Credentials")
)
  $context = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
  $context.Credentials = $Credential
  $web = $context.Web
  $context.Load($web)
  $context.Load($web.Webs)
  $context.ExecuteQuery()
  foreach($web in $web.Webs) {
    Get-SPOWebs -Url $web.Url -Credential $Credential $web
  }
}
#Retrieve all site collection infos
Connect-SPOService -Url $AdminUrl -Credential $Credentials
$sites = Get-SPOSite
#Retrieve and print all sites
foreach ($site in $sites)
{
    Write-Host 'Site collection:' $site.Url
    $AllWebs = Get-SPOWebs -Url $site.Url -Credential $SPOCredentials
    $AllWebs | ForEach-Object { Write-Host $_.Title }
    Write-Host '-----------------------------'
}
#
$AllWebs = Get-SPOWebs -Url 'https://domain.sharepoint.com' -Credential $SPOCredentials
$AllWebs | ForEach-Object { Write-Host $_.Title }
