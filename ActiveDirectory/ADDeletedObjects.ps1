<#
.SYNOPSIS
    Lists or restores deleted Active Directory objects.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$Identity,

    [string]$SearchBase,

    [switch]$Restore
)

$parameters = @{ IncludeDeletedObjects = $true; Properties = '*' }

if ($Identity) {
    $objects = @(Get-ADObject -Identity $Identity @parameters)
}
else {
    if ($SearchBase) { $parameters.SearchBase = $SearchBase }
    $objects = @(Get-ADObject -LDAPFilter '(isDeleted=TRUE)' @parameters)
}

if (-not $Restore) {
    $objects | Select-Object Name, ObjectClass, LastKnownParent, WhenChanged, DistinguishedName
    return
}

if (-not $Identity) { throw '-Identity is required when -Restore is specified.' }
foreach ($object in $objects) {
    if ($PSCmdlet.ShouldProcess($object.DistinguishedName, 'Restore deleted Active Directory object')) {
        $object | Restore-ADObject -PassThru
    }
}
