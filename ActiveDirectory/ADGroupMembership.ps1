<#
.SYNOPSIS
    Exports membership for selected Active Directory groups or all groups.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(DefaultParameterSetName = 'Selected')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Selected')]
    [string[]]$Group,

    [Parameter(Mandatory, ParameterSetName = 'All')]
    [switch]$AllGroups,

    [string]$Server,

    [string]$OutputPath
)

$adParameters = @{}
if ($Server) { $adParameters.Server = $Server }
$groups = if ($AllGroups) { Get-ADGroup -Filter * @adParameters } else { $Group | ForEach-Object { Get-ADGroup -Identity $_ @adParameters } }

$rows = foreach ($adGroup in $groups) {
    $members = @(Get-ADGroupMember -Identity $adGroup -Recursive @adParameters)
    if ($members.Count -eq 0) {
        [pscustomobject]@{ GroupName = $adGroup.Name; MemberName = $null; SamAccountName = $null; ObjectClass = $null; DistinguishedName = $null }
    }
    foreach ($member in $members) {
        [pscustomobject]@{
            GroupName         = $adGroup.Name
            MemberName        = $member.Name
            SamAccountName    = $member.SamAccountName
            ObjectClass       = $member.ObjectClass
            DistinguishedName = $member.DistinguishedName
        }
    }
}
if ($OutputPath) { $rows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 }
$rows
