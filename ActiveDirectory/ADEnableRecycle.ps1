<#
.SYNOPSIS
    Enables the Active Directory Recycle Bin optional feature.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$ForestName = (Get-ADForest).Name
)

if ($PSCmdlet.ShouldProcess($ForestName, 'Enable Active Directory Recycle Bin (irreversible)')) {
    Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $ForestName -Confirm:$false
}
