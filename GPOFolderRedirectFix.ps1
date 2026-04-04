<#
.SYNOPSIS
    Manages group policy folder redirect fix.
#>

### FOLDER REDIRECTION GPO FIX ###
reg export "HKLM:\Software\Policies\Microsoft" C:\HKLM_MicrosoftBkUp.reg
Remove-Item -Path “HKLM:\Software\Policies\Microsoft” -Recurse -Force
reg export "HKCU:\Software\Policies\Microsoft" C:\HKCU_MicrosoftBkUp.reg
Remove-Item -Path “HKCU:\Software\Policies\Microsoft” -Recurse -Force
reg export "HKCU:\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects" C:\HKCU_GPOBkUp.reg
Remove-Item -Path “HKCU:\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects” -Recurse -Force
reg export "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies" C:\HKCU_PoliciesBkUp.reg
Remove-Item -Path “HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies” -Recurse -Force
Set-DNSClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("172.16.17.10","172.16.17.20")
ipconfig /flushdns
gpupdate /force
Set-DNSClientServerAddress -InterfaceAlias "Ethernet" -ResetServerAddresses
Read-Host -Prompt "Press Enter to exit"