<#
.SYNOPSIS
    Promotes Active Directory domain controller.
#>

# Install Server Role
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
# Install PowerShell Module
Import-Module ADDSDeployment
# Promote to DC
Install-ADDSDomainController -DomainName databasedads.com `
                            -Credential (Get-Credential) `
                            -InstallDNS:$true `
                            -NoGlobalCatalog:$false `
                            -DatabasePath "C:\Windows\NTDS" `
                            -Logpath "C:\Windows\Logs" `
                            -SysvolPath "C:\Windows\SYSVOL” `
                            -Sitename hq-databasedads-com `
                            -IncludeManagementTools