New-NetIPAddress -InterfaceAlias ethernet -IPAddress 192.168.0.10 -PrefixLength 24 -DefaultGateway 192.168.0.1
Start-Sleep 3
Set-DNSClientServerAddress -InterfaceAlias "Ethernet" -ServerAddress 9.9.9.9
Start-Sleep 3
Rename-Computer NewMachine01
Start-Sleep 3
Restart-Computer