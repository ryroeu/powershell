<#
.SYNOPSIS
    Manages rsati nstall windows 10.
#>

### Install RSAT ###
Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "NotPresent"} | Add-WindowsCapability -Online