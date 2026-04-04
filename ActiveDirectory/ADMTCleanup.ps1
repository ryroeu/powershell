<#
.SYNOPSIS
    Cleans up ADMT.
#>

Import-Module Microsoft.PowerShell.Management

Write-Host "Stopping ADMT Agent.." -ForegroundColor Magenta
Stop-Process -Name "admagnt" -Confirm:$false -Force

Write-Host "Removing ADMT Service.." -ForegroundColor Magenta
Remove-Service -Name "OnePointdomainAgent" -Confirm:$false -Force

Write-Host "Removng Registry SubKey.." -ForegroundColor Magenta
Remove-Item HKLM:\Software\Microsoft\ADMT -Recurse -Confirm:$false -Force

Write-Host "Removing ADMT Directory.." -ForegroundColor Magenta
Remove-Item C:\Windows\ADMT -Recurse -Confirm:$false -Force
