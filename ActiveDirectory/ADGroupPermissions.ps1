<#
.SYNOPSIS
    Manages active directory group permissions.
#>

# VIEW ACCESS RIGHTS ON GROUP OBJECT
$GroupName = Get-Content .\GroupNames.txt
(Get-ACL (Get-ADGroup $GroupName)).Access | Select-Object IdentityReference, `
                                                          ActiveDirectoryRights, `
                                                          AccessControlType, `
                                                          IsInherited, `
                                                          InheritanceType, `
                                                          InheritanceFlags, `
                                                          PropagationFlags, `
                                                          ObjectFlags, `
                                                          ObjectType, `
                                                          InheritedObjectType `
                                          | Export-Csv .\GroupAccess.csv -NoTypeInformation



# VIEW PERMISSIONS OF NON-INHERITED USERS ON SPECIFIC ORGANIZATIONAL UNIT (OU)
$Path = Get-Content .\Paths.txt
(Get-ACL $Path).Access | Where-Object {$_.IsInherited -eq $FALSE} | Select-Object IdentityReference, `
                                                                                  ActiveDirectoryRights, `
                                                                                  AccessControlType, `
                                                                                  IsInherited, `
                                                                                  InheritanceType, `
                                                                                  InheritanceFlags, `
                                                                                  PropagationFlags, `
                                                                                  ObjectFlags, `
                                                                                  ObjectType, `
                                                                                  InheritedObjectType `
                                                                  | Export-Csv .\GroupPermissions.csv -NoTypeInformation