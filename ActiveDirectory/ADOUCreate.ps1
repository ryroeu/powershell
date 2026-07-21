<#
.SYNOPSIS
    Creates an Active Directory organizational unit.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [string]$Path,

    [string]$Description,

    [bool]$ProtectedFromAccidentalDeletion = $true
)

$parameters = @{ Name = $Name; ProtectedFromAccidentalDeletion = $ProtectedFromAccidentalDeletion }
if ($Path) { $parameters.Path = $Path }
if ($Description) { $parameters.Description = $Description }
if ($PSCmdlet.ShouldProcess(($Path ?? (Get-ADDomain).DistinguishedName), "Create OU '$Name'")) {
    New-ADOrganizationalUnit @parameters -PassThru
}
