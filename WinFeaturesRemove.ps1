<#
.SYNOPSIS
    Removes Windows features.
#>

Get-WindowsFeature | Where-Object {$_.Installed -match "False"} | Uninstall-WindowsFeature -Remove