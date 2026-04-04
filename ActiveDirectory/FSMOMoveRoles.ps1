<#
.SYNOPSIS
    Moves FSMO roles.
#>

# Select target DC
$Server = Get-ADDomainController -Identity "dc.domain.com"
# Move roles to target DC
Move-ADDirectoryServerOperationMasterRole -Identity $Server -OperationMasterRole SchemaMaster,DomainNamingMaster,PDCEmulator,RIDMaster,InfrastructureMaster