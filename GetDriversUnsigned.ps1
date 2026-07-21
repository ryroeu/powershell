<#
.SYNOPSIS
    Retrieves unsigned Plug and Play drivers from Windows.
#>

[CmdletBinding()]
param()

Get-CimInstance -ClassName Win32_PnPSignedDriver |
    Where-Object IsSigned -EQ $false |
    Select-Object DeviceName, Manufacturer, DriverVersion, DriverDate
