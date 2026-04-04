<#
.SYNOPSIS
    Retrieves DHCP leases.
#>

Export-DhcpServer -ComputerName "dhcpserver.contoso.com" -File "C:\exportdir\dhcpexport.xml" -ScopeId 10.10.10.0,10.20.20.0 -Leases
