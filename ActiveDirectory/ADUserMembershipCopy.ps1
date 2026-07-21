<#
.SYNOPSIS
    Copies Active Directory group memberships from one user to one or more destination users.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$SourceUser,

    [Parameter(Mandatory)]
    [string[]]$DestinationUser,

    [string]$Server
)

$parameters = @{}
if ($Server) { $parameters.Server = $Server }
$source = Get-ADUser -Identity $SourceUser @parameters
$groups = @(Get-ADPrincipalGroupMembership -Identity $source @parameters)

foreach ($destinationName in $DestinationUser) {
    $destination = Get-ADUser -Identity $destinationName @parameters
    $currentGroupDns = @(Get-ADPrincipalGroupMembership -Identity $destination @parameters | Select-Object -ExpandProperty DistinguishedName)
    foreach ($group in $groups | Where-Object DistinguishedName -NotIn $currentGroupDns) {
        if ($PSCmdlet.ShouldProcess($destination.SamAccountName, "Add to group '$($group.Name)'")) {
            Add-ADGroupMember -Identity $group -Members $destination @parameters
        }
    }
}
