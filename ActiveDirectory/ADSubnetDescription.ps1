<#
.SYNOPSIS
    Sets an Active Directory replication subnet description.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Description,

    [string]$Server
)

$parameters = @{ Identity = $Identity; Description = $Description }
if ($Server) { $parameters.Server = $Server }
if ($PSCmdlet.ShouldProcess($Identity, "Set subnet description to '$Description'")) {
    Set-ADReplicationSubnet @parameters -PassThru
}
