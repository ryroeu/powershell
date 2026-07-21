<#
.SYNOPSIS
    Sets an Active Directory site-link replication interval.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$Identity = 'DEFAULTIPSITELINK',

    [Parameter(Mandatory)]
    [ValidateRange(15, 10080)]
    [int]$Minutes
)

if ($PSCmdlet.ShouldProcess($Identity, "Set replication interval to $Minutes minutes")) {
    Set-ADReplicationSiteLink -Identity $Identity -ReplicationFrequencyInMinutes $Minutes -PassThru
}
