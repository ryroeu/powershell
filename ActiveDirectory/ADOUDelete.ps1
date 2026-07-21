<#
.SYNOPSIS
    Deletes an Active Directory organizational unit.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [switch]$Recursive
)

$ou = Get-ADOrganizationalUnit -Identity $Identity -Properties ProtectedFromAccidentalDeletion
if ($ou.ProtectedFromAccidentalDeletion) {
    if ($PSCmdlet.ShouldProcess($ou.DistinguishedName, 'Disable accidental-deletion protection')) {
        Set-ADOrganizationalUnit -Identity $ou -ProtectedFromAccidentalDeletion $false
    }
}
if ($PSCmdlet.ShouldProcess($ou.DistinguishedName, 'Delete organizational unit')) {
    Remove-ADOrganizationalUnit -Identity $ou -Recursive:$Recursive -Confirm:$false
}
