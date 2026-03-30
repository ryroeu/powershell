Write-Output "Setting PSGallery as a Trusted repo"
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Write-Output "PSGallery is Trusted"
Write-Output "Installing Modules.."
Install-Module -Name 7Zip4Powershell -Confirm:$false
Install-Module -Name ActiveDirectoryDsc -Confirm:$false
Install-Module -Name AWSPowerShell -Confirm:$false
Install-Module -Name AWS.Tools.Common -Confirm:$false
Install-Module -Name Az -Confirm:$false
Install-Module -Name CertificateDsc -Confirm:$false
Install-Module -Name ChocolateyGet -Confirm:$false
Install-Module -Name ComputerManagementDsc -Confirm:$false
Install-Module -Name DellBIOSProvider -Confirm:$false
Install-Module -Name ExchangeOnlineManagement -Confirm:$false
Install-Module -Name IISAdministration -Confirm:$false
Install-Module -Name Microsoft.Graph -Confirm:$false
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Confirm:$false
Install-Module -Name NetworkingDsc -Confirm:$false
Install-Module -Name NuGet -Confirm:$false
Install-Module -Name PackageManagement -Confirm:$false
Install-Module -Name PnP.PowerShell -Confirm:$false
Install-Module -Name PowerShellGet -Force
Install-Module -Name PSScriptAnalyzer -Confirm:$false
Install-Module -Name PSWindowsUpdate -Confirm:$false
Install-Module -Name SqlServerDsc -Confirm:$false
Install-Module -Name VMware.PowerCLI -Confirm:$false
Write-Output "Finished. Displaying installed modules.."
Get-InstalledModule
