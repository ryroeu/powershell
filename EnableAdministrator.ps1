<#
.SYNOPSIS
    Enables administrator.
#>

Get-LocalUser -Name "Administrator" | Enable-LocalUser
Set-LocalUser -Name "Administrator" -Password $Password