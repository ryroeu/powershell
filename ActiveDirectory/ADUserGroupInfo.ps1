<#
.SYNOPSIS
    Expands Active Directory users and groups found in file-system ACLs.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
    [string[]]$Path,

    [string]$OutputPath
)

$results = foreach ($itemPath in $Path) {
    $resolvedPath = (Resolve-Path -LiteralPath $itemPath -ErrorAction Stop).Path
    $accessRules = (Get-Acl -LiteralPath $resolvedPath).Access |
        Where-Object { $_.IdentityReference -notmatch '^(BUILTIN|NT AUTHORITY)\\|^Everyone$|^S-1-5-' }

    foreach ($accessRule in $accessRules) {
        $identity = $accessRule.IdentityReference.Value -replace '^.*\\', ''
        $escapedIdentity = $identity.Replace("'", "''")
        $adObject = Get-ADObject -Filter "SamAccountName -eq '$escapedIdentity'" -Properties SamAccountName, DisplayName, Description, Enabled |
            Select-Object -First 1
        if (-not $adObject) {
            Write-Warning "Could not resolve '$($accessRule.IdentityReference)' in Active Directory."
            continue
        }

        $members = if ($adObject.ObjectClass -eq 'group') {
            @(Get-ADGroupMember -Identity $adObject -Recursive -ErrorAction Stop)
        }
        else {
            @($adObject)
        }

        foreach ($member in $members) {
            $details = Get-ADObject -Identity $member.DistinguishedName -Properties SamAccountName, DisplayName, Enabled
            [pscustomobject]@{
                Path              = $resolvedPath
                IdentityReference = $accessRule.IdentityReference.Value
                Permission        = $accessRule.FileSystemRights
                AccessControlType = $accessRule.AccessControlType
                IsInherited       = $accessRule.IsInherited
                MemberName        = $details.SamAccountName
                MemberDisplayName = $details.DisplayName
                MemberObjectClass = $details.ObjectClass
                MemberEnabled     = $details.Enabled
                MembershipSource  = if ($adObject.ObjectClass -eq 'group') { $adObject.SamAccountName } else { 'Direct' }
            }
        }
    }
}

if ($OutputPath) {
    $results | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8NoBOM
}
$results
