<#
.SYNOPSIS
    Retrieves drivers all.
#>

### Display Driver Information ###
Get-CimInstance -ClassName Win32_PnPSignedDriver | Select-Object DeviceName, Manufacturer, DriverVersion, IsSigned, Signer
Read-Host -Prompt "Press Enter to exit"