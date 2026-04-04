<#
.SYNOPSIS
    Enables Active Directory recycle.
#>

Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target domain.comx