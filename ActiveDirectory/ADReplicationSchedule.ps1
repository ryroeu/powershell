<#
.SYNOPSIS
    Configures the daily replication window for an Active Directory site link.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$Identity = 'DEFAULTIPSITELINK',

    [ValidateRange(0, 23)]
    [int]$StartHour = 8,

    [ValidateRange(0, 23)]
    [int]$EndHour = 17
)

$schedule = [DirectoryServices.ActiveDirectory.ActiveDirectorySchedule]::new()
$schedule.SetDailySchedule(
    [DirectoryServices.ActiveDirectory.HourOfDay]$StartHour,
    [DirectoryServices.ActiveDirectory.MinuteOfHour]::Zero,
    [DirectoryServices.ActiveDirectory.HourOfDay]$EndHour,
    [DirectoryServices.ActiveDirectory.MinuteOfHour]::Zero
)
if ($PSCmdlet.ShouldProcess($Identity, "Set daily replication window to $StartHour`:00-$EndHour`:00")) {
    Set-ADReplicationSiteLink -Identity $Identity -ReplicationSchedule $schedule -PassThru
}
