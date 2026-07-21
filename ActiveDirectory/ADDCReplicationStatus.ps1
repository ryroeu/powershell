<#
.SYNOPSIS
    Retrieves Active Directory replication partner status and optionally starts synchronization.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$Target = (Get-ADDomain).DNSRoot,

    [switch]$Synchronize
)

if ($Synchronize) {
    foreach ($controller in Get-ADDomainController -Filter *) {
        if ($PSCmdlet.ShouldProcess($controller.HostName, 'Synchronize all directory partitions')) {
            & repadmin.exe /syncall $controller.HostName /A /e /P | Out-Null
            if ($LASTEXITCODE -ne 0) { Write-Warning "Repadmin failed for '$($controller.HostName)' with exit code $LASTEXITCODE." }
        }
    }
}

Get-ADReplicationPartnerMetadata -Target $Target -Scope Domain |
    Select-Object Server, Partner, Partition, LastReplicationAttempt, LastReplicationSuccess, LastReplicationResult, ConsecutiveReplicationFailures
