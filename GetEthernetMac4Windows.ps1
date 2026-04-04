<#
.SYNOPSIS
    Retrieves ethernet mac 4 Windows.
#>

### Display MAC Addresses ###
Get-NetAdapter | Where-Object {$_.Name -like "Ethernet"} | Select-Object -ExpandProperty MacAddress
Read-Host -Prompt "Press Enter to exit"