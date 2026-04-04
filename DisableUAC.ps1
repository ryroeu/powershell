<#
.SYNOPSIS
    Disables uac.
#>

### Disable UAC ###
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system" -Name EnableLUA -Value "0" -Force