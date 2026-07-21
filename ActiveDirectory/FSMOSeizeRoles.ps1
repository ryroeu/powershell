<#
.SYNOPSIS
    Seizes selected FSMO roles on a domain controller.
.DESCRIPTION
    Only use seizure when the previous role holder will never return to the domain.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [ValidateSet('SchemaMaster', 'DomainNamingMaster', 'PDCEmulator', 'RIDMaster', 'InfrastructureMaster')]
    [string[]]$Role = @('SchemaMaster', 'DomainNamingMaster', 'PDCEmulator', 'RIDMaster', 'InfrastructureMaster')
)

if ($PSCmdlet.ShouldProcess($Identity, "Seize FSMO roles: $($Role -join ', ')")) {
    Move-ADDirectoryServerOperationMasterRole -Identity $Identity -OperationMasterRole $Role -Force -Confirm:$false -PassThru
}
