<#
.SYNOPSIS
    Retrieves FSMO roles.
#>

### Get FSMO Roles ###
Get-ADForest domain.com | Format-Table SchemaMaster
Get-ADForest domain.com | Format-Table DomainNamingMaster
Get-ADForest domain.com | Format-Table PDCEmulator
Get-ADForest domain.com | Format-Table InfrastructureMaster
Get-ADForest domain.com | Format-Table RIDMaster
