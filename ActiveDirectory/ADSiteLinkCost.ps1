<#
.SYNOPSIS
    Manages active directory site link cost.
#>

# Change Cost of AD Site Link
Set-ADReplicationSiteLink -Identity DEFAULTIPSITELINK -Cost 50 -Force