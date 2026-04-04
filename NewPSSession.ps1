<#
.SYNOPSIS
    Creates PowerShell session.
#>

$global:s = New-PSSession -ComputerName Server1.Domain44.Corpnet.Fabrikam.com -Credential Domain01\Admin01
Get-PSSession | Connect-PSSession