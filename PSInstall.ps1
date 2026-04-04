<#
.SYNOPSIS
    Installs PowerShell.
#>

Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.6.0/PowerShell-7.6.0-win-x64.msi -Outfile C:\Temp\PowerShell-7.6.0.msi
Set-Location C:\Temp 
.\PowerShell-7.6.0.msi