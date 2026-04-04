<#
.SYNOPSIS
    Installs PowerShell.
#>

Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi -Outfile C:\Temp\PowerShell-7.4.2.msi
Set-Location C:\Temp 
.\PowerShell-7.4.2.msi