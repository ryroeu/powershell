<#
.SYNOPSIS
    Manages active directory group membership.
#>

### Export Domain Admins Group to CSV ###
Get-ADGroupMember -Server domain.com `
                  -Identity "Domain Admins" `
                  -Recursive | Export-Csv -Path C:\ExportDir\DomainAdmins.csv

### Export Local Admins Group to CSV ###
Get-ADGroupMember -Server domain.com `
                  -Identity "Local Admin Users" `
                  -Recursive | Export-Csv -Path C:\ExportDir\LocalAdmins.csv

### Export All Groups and their Membership to CSV ###
Get-ADGroup -Server domain.com `
            -Filter * `
            -Properties * `
            | Select-Object -Property Name, GroupCategory, GroupScope, DistinguishedName, Description, ManagedBy, @{Name="Members";Expression={($_ | Get-ADGroupMember | Select-Object -ExpandProperty Name) -join ";"}} `
            | Export-Csv -Path C:\ExportDir\AllGroups.csv