<#
.SYNOPSIS
    Manages active directory replication schedule.
#>

# Set AD Replication schedule to 8am-5pm / Sunday-Saturday
$replicationSchedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule 
$replicationSchedule.SetDailySchedule("Eight","Zero","Seventeen","Zero")
Import-Module ActiveDirectory
Set-ADReplicationSiteLink DEFAULTIPSITELINK -ReplicationSchedule $replicationSchedule
