<#
.SYNOPSIS
    Creates DHCP.
#>

### Set IP / DNS on Server ###
New-NetIPAddress -IPAddress 10.0.0.3 `
                 -InterfaceAlias "Ethernet" `
                 -DefaultGateway 10.0.0.1 `
                 -AddressFamily IPv4 `
                 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
                           -ServerAddresses 10.0.0.2

### Rename Server ###
Rename-Computer -Name DHCP1
Restart-Computer

### Add Server to Domain ###
Add-Computer DOMAIN
Restart-Computer

### Install DHCP Role ###
Install-WindowsFeature DHCP -IncludeManagementTools

### Security Groups ###
netsh dhcp add securitygroups
Restart-service dhcpserver

### Authorize Server on Domain ###
Add-DhcpServerInDC -DnsName DHCP1.corp.contoso.com `
                   -IPAddress 10.0.0.3
Get-DhcpServerInDC

### Appeal ServMan Message ###
Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 `
                 –Name ConfigurationState `
                 –Value 2

### Config Dynamic DNS Updates ###
Set-DhcpServerv4DnsSetting -ComputerName "DHCP1.corp.contoso.com" `
                           -DynamicUpdates "Always" `
                           -DeleteDnsRRonLeaseExpiry $True

### Config Dynamic DNS Update Creds ###
$Credential = Get-Credential
Set-DhcpServerDnsCredential -Credential $Credential `
                            -ComputerName "DHCP1.corp.contoso.com"

### Config CorpNet Scope ###
Add-DhcpServerv4Scope -Name "Corpnet" `
                      -StartRange 10.0.0.1 `
                      -EndRange 10.0.0.254 `
                      -SubnetMask 255.255.255.0 `
                      -State Active`
Add-DhcpServerv4ExclusionRange -ScopeID 10.0.0.0 `
                               -StartRange 10.0.0.1 `
                               -EndRange 10.0.0.15`
Set-DhcpServerv4OptionValue -OptionID 3 `
                            -Value 10.0.0.1 `
                            -ScopeID 10.0.0.0 `
                            -ComputerName DHCP1.corp.contoso.com`
Set-DhcpServerv4OptionValue -DnsDomain corp.contoso.com `
                            -DnsServer 10.0.0.2

### Config CorpNet Scopes for additional Subnets ###
Add-DhcpServerv4Scope -Name "Corpnet2" `
                      -StartRange 10.0.1.1 `
                      -EndRange 10.0.1.254 `
                      -SubnetMask 255.255.255.0 `
                      -State Active
Add-DhcpServerv4ExclusionRange -ScopeID 10.0.1.0 `
                               -StartRange 10.0.1.1 `
                               -EndRange 10.0.1.15
Set-DhcpServerv4OptionValue -OptionID 3 `
                            -Value 10.0.1.1 `
                            -ScopeID 10.0.1.0 `
                            -ComputerName DHCP1.corp.contoso.com