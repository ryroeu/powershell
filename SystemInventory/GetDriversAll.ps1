<#
.SYNOPSIS
    Retrieves signed Plug and Play driver information from Windows.
#>

[CmdletBinding()]
param()

Get-CimInstance -ClassName Win32_PnPSignedDriver |
    Select-Object DeviceName, Manufacturer, DriverVersion, DriverDate, IsSigned, Signer
