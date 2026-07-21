<#
.SYNOPSIS
    Assigns an Active Directory replication subnet to a site.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [Parameter(Mandatory)]
    [string]$Site
)

if ($PSCmdlet.ShouldProcess($Identity, "Assign subnet to site '$Site'")) {
    Set-ADReplicationSubnet -Identity $Identity -Site $Site -PassThru
}
