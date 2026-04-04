<#
.SYNOPSIS
    Disables uacp rompts.
#>

### Enable UAC but Disable Prompts ###
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name “EnableLUA” -Value "1" -Force        
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name “ConsentPromptBehaviorAdmin” -Value "0" -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name “ConsentPromptBehaviorUser” -Value "0" -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name “PromptOnSecureDesktop” -Value "0" -Force