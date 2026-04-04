<#
.SYNOPSIS
    Manages active directory subnet location.
#>

# Change AD Subnet Location
Set-ADReplicationSubnet -Identity 10.0.0.0/8 -Location "New location here”
