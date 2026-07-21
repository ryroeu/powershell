<#
.SYNOPSIS
    Deletes an Active Directory replication subnet.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Identity
)

if ($PSCmdlet.ShouldProcess($Identity, 'Delete Active Directory replication subnet')) {
    Remove-ADReplicationSubnet -Identity $Identity -Confirm:$false
}
