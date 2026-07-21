<#
.SYNOPSIS
    Reports explicit permissions on Active Directory groups and file-system paths.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string[]]$GroupIdentity,

    [string[]]$Path,

    [string]$OutputPath
)

if (-not $GroupIdentity -and -not $Path) {
    throw 'Specify at least one -GroupIdentity or -Path value.'
}

$results = @(
    foreach ($group in $GroupIdentity) {
        $adGroup = Get-ADGroup -Identity $group -ErrorAction Stop
        $acl = Get-Acl -LiteralPath "AD:$($adGroup.DistinguishedName)"
        foreach ($access in $acl.Access) {
            [pscustomobject]@{
                TargetType             = 'ActiveDirectoryGroup'
                Target                 = $adGroup.DistinguishedName
                IdentityReference      = $access.IdentityReference
                Rights                 = $access.ActiveDirectoryRights
                AccessControlType      = $access.AccessControlType
                IsInherited            = $access.IsInherited
                InheritanceType        = $access.InheritanceType
                ObjectType             = $access.ObjectType
                InheritedObjectType    = $access.InheritedObjectType
            }
        }
    }

    foreach ($itemPath in $Path) {
        $resolvedPath = (Resolve-Path -LiteralPath $itemPath -ErrorAction Stop).Path
        foreach ($access in (Get-Acl -LiteralPath $resolvedPath).Access | Where-Object IsInherited -eq $false) {
            [pscustomobject]@{
                TargetType             = 'FileSystemPath'
                Target                 = $resolvedPath
                IdentityReference      = $access.IdentityReference
                Rights                 = $access.FileSystemRights
                AccessControlType      = $access.AccessControlType
                IsInherited            = $access.IsInherited
                InheritanceType        = $access.InheritanceFlags
                ObjectType             = $null
                InheritedObjectType    = $null
            }
        }
    }
)

if ($OutputPath) {
    $results | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8NoBOM
}
$results
