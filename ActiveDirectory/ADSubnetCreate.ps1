<#
.SYNOPSIS
    Creates an Active Directory replication subnet.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F:.]+/\d+$')]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Site,

    [string]$Description,

    [string]$Location
)

$parameters = @{ Name = $Name; Site = $Site }
if ($Description) { $parameters.Description = $Description }
if ($Location) { $parameters.Location = $Location }
if ($PSCmdlet.ShouldProcess($Name, "Create replication subnet for site '$Site'")) {
    New-ADReplicationSubnet @parameters -PassThru
}
