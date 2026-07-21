<#
.SYNOPSIS
    Sets an Active Directory replication subnet location.
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
if ($PSCmdlet.ShouldProcess($Identity, "Set subnet location to '$Location'")) {
    Set-ADReplicationSubnet @parameters -PassThru
}
