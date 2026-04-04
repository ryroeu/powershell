<#
.SYNOPSIS
    Manages active directory subnet description.
#>

# Change AD Subnet Description
Set-ADReplicationSubnet -Identity 10.0.0.0/8 -Description "New description here”
