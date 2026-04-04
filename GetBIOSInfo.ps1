<#
.SYNOPSIS
    Retrieves BIOS information.
#>

### Display BIOS Information ###
Get-CimInstance -ClassName Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate, SerialNumber | Format-Table -AutoSize
Read-Host -Prompt "Press Enter to exit"