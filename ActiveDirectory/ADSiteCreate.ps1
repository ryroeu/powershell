<#
.SYNOPSIS
    Creates an Active Directory replication site.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [string]$Description,

    [string]$Server
)

$parameters = @{ Name = $Name }
if ($Description) { $parameters.Description = $Description }
if ($Server) { $parameters.Server = $Server }
if ($PSCmdlet.ShouldProcess($Name, 'Create Active Directory replication site')) {
    New-ADReplicationSite @parameters -PassThru
}
