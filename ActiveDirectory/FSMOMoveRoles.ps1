<#
.SYNOPSIS
    Transfers selected FSMO roles to a domain controller.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [ValidateSet('SchemaMaster', 'DomainNamingMaster', 'PDCEmulator', 'RIDMaster', 'InfrastructureMaster')]
    [string[]]$Role = @('SchemaMaster', 'DomainNamingMaster', 'PDCEmulator', 'RIDMaster', 'InfrastructureMaster')
)

if ($PSCmdlet.ShouldProcess($Identity, "Transfer FSMO roles: $($Role -join ', ')")) {
    Move-ADDirectoryServerOperationMasterRole -Identity $Identity -OperationMasterRole $Role -Confirm:$false -PassThru
}
