<#
.SYNOPSIS
    Creates Active Directory subnet.
#>

# Create New Subnet
New-ADReplicationSubnet -Name 10.0.0.0/8 -Site Default-First-Site-Name
