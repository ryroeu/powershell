<#
.SYNOPSIS
    Retrieves forest-wide and domain-wide FSMO role holders.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$Forest,

    [string]$Domain
)

$forestObject = if ($Forest) { Get-ADForest -Identity $Forest } else { Get-ADForest }
$domainObject = if ($Domain) { Get-ADDomain -Identity $Domain } else { Get-ADDomain }

[pscustomobject]@{
    SchemaMaster         = $forestObject.SchemaMaster
    DomainNamingMaster   = $forestObject.DomainNamingMaster
    PDCEmulator          = $domainObject.PDCEmulator
    RIDMaster            = $domainObject.RIDMaster
    InfrastructureMaster = $domainObject.InfrastructureMaster
}
