<#
.SYNOPSIS
    Creates description local.
#>

Set-CimInstance -Query "SELECT * FROM Win32_OperatingSystem" -Property @{ Description = "ComputerName" }