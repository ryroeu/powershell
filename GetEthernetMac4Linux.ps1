<#
.SYNOPSIS
    Retrieves ethernet mac 4 linux.
#>

# Get Mac Address of Ethernet Interface
$mac = ifconfig en0 | grep ether | awk '{print $2}'
Write-Output "The MAC Address of your ethernet adapter is $mac"