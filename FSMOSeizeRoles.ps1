<#
.SYNOPSIS
    Seizes FSMO roles.
#>

# Move roles to this DC
Move-ADDirectoryServerOperationMasterRole -Identity NewMaster.domain.com -OperationMasterRole SchemaMaster,DomainNamingMaster,PDCEmulator,RIDMaster,InfrastructureMaster -Force
