<#
.SYNOPSIS
    Manages active directory site link interval.
#>

# Change AD Site Link Replication Interval
Set-ADReplicationSiteLink -Identity DEFAULTIPSITELINK -ReplicationFrequencyInMinutes 30
