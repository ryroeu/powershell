<#
.SYNOPSIS
    Retrieves drivers unsigned.
#>

### Display Unsigned Drivers ###
Get-CimInstance -ClassName Win32_PnPSignedDriver | Where-Object {-not $_.IsSigned} | Select-Object DeviceName, Manufacturer, DriverVersion
Read-Host -Prompt "Press Enter to exit"