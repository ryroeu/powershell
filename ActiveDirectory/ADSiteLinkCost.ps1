<#
.SYNOPSIS
    Sets an Active Directory site-link cost.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$Identity = 'DEFAULTIPSITELINK',

    [Parameter(Mandatory)]
    [ValidateRange(1, 99999)]
    [int]$Cost
)

if ($PSCmdlet.ShouldProcess($Identity, "Set site-link cost to $Cost")) {
    Set-ADReplicationSiteLink -Identity $Identity -Cost $Cost -PassThru
}
