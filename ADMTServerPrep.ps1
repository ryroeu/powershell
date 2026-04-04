<# NOT INTENDED TO BE RAN AS A SCRIPT. THIS IS A COLLECTION OF SNIPPETS FOR AN AD MIGRATION.
THIS IS A WORK IN PROGRESS. WAS WRITTEN IN A FEW MINUTES FROM MEMORY. #>


#################### Set DNS IP Addresses on each DC ####################
Set-DNSClientServerAddress -InterfaceAlias "Ethernet" -ServerAddress ("10.0.0.1","10.0.0.2")


#################### Install AD Module ####################
Import-Module ActiveDirectory


#################### Create Trust relationship between DCs ####################
$strRemoteForest = "remoteforestname.com"
$strRemoteAdmin = "Administrator"
$strRemoteAdminPassword = "Password"
$remoteContext = New-Object -TypeName"System.DirectoryServices.ActiveDirectory.DirectoryContext" -ArgumentList @( "Forest",$strRemoteForest, $strRemoteAdmin, $strRemoteAdminPassword)
try {
    $remoteForest =[System.DirectoryServices.ActiveDirectory.Forest]::getForest($remoteContext)
    #Write-Host "GetRemoteForest: Succeeded for domain $($remoteForest)"
}
catch {
    Write-Warning "GetRemoteForest: Failed:`n`tError: $($($_.Exception).Message)"
}
Write-Host "Connected to Remote forest: $($remoteForest.Name)"
$localforest=[System.DirectoryServices.ActiveDirectory.Forest]::getCurrentForest()
Write-Host "Connected to Local forest: $($localforest.Name)"
try {
    $localForest.CreateTrustRelationship($remoteForest,"Inbound")
    Write-Host "CreateTrustRelationship: Succeeded for domain $($remoteForest)"
}
catch {
    Write-Warning "CreateTrustRelationship: Failed for domain$($remoteForest)`n`tError: $($($_.Exception).Message)"
}


#################### Install GP Module ####################
Import-Module GroupPolicy


#################### Set DNS Suffix Search List ####################
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name 'NV Domain' -Value ("olddomain.com","newdomain.com")


#################### Switch to Downloads Dir ####################
Set-Location $env:userprofile\Downloads


#################### Download and Install SQL Express ####################
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=866658" -OutFile $env:userprofile\Downloads
#Install SQL Server Express
.\SQL2019-SSEI-Expr.exe


#################### Download and Install ADMT ####################
Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56570" -OutFile $env:userprofile\Downloads
#Install ADMT
.\admtsetup32.exe


#################### Create Encryption Key ####################
ADMT key /Option:Create /SourceDomain:domain.com /KeyFile:C:\mykey.pes /KeyPassword:Password


#################### Add Administrator to each Domain's Administrators Group ####################
$User = Get-ADUser -Identity "CN=Chew David,OU=UserAccounts,DC=NORTHAMERICA,DC=FABRIKAM,DC=COM" -Server "northamerica.fabrikam.com"
$Group = Get-ADGroup -Identity "CN=AccountLeads,OU=UserAccounts,DC=EUROPE,DC=FABRIKAM,DC=COM" -Server "europe.fabrikam.com"
Add-ADGroupMember -Identity $Group -Members $User -Server "europe.fabrikam.com"


#################### Download and Install ADMT Password DLL ####################
Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/confirmation.aspx?id=1838" -OutFile $env:userprofile\Downloads
#install ADMT Password DLL
msiexec.exe /i .\pwdmig.msi


#################### Start Password Export Server Service ####################
Get-Service -Displayname "Password Export*" | Start-Service


#################### Create new OUs on target domain ####################
New-ADOrganizationalUnit -Name "OldDomainName" -Path "DC=NEWDOMAIN,DC=COM"
New-ADOrganizationalUnit -Name "Users" -Path "DC=NEWDOMAIN,DC=COM,OU=OLDDOMAINNAME"


#Get coffee and reset before commencing migrations