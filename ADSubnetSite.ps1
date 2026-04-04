<#
.SYNOPSIS
    Manages active directory subnet site.
#>

# Change the Site for AD Subnet
Set-ADReplicationSubnet -Identity 10.0.0.0/8 -Site NewSiteName
