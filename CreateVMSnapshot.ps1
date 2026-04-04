<#
.SYNOPSIS
    Creates virtual machine snapshot.
#>

### Create New Snapshot of VM ###
Get-VM -Name "NameofVM" | Checkpoint-VM -SnapshotName "NameOfSnapshot" -Confirm:$false