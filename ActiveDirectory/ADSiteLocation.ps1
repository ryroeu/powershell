<#
.SYNOPSIS
    Sets an Active Directory replication site location.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Location,

    [string]$Server
)

$parameters = @{ Identity = $Identity; Location = $Location }
if ($Server) { $parameters.Server = $Server }
if ($PSCmdlet.ShouldProcess($Identity, "Set site location to '$Location'")) {
    Set-ADReplicationSite @parameters -PassThru
}
