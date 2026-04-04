<#
.SYNOPSIS
    Copies Active Directory user membership.
#>

# CHANGE VARIABLES TO YOUR NEEDS #
$Server = "domain.com" #Domain that Users are in
$SourceUser = Get-ADUser -Identity "SamAccountName" -Server $Server #User (SAMAccountName) you are copying 'MemberOf' Groups from
$DestUser = Get-ADUser -Identity "SamAccountName" -Server $Server #User (SAMAccountName) you are copying 'MemberOf' Groups to
#$DestUserList = #List of Users (SAMAccountName)s you are copying 'MemberOf' Groups to - Optional

Get-ADPrincipalGroupMembership $SourceUser | Select-Object SamAccountName | Export-Csv -Path "C:\ExportDir\Groups.csv"
$Groups = Import-Csv -Path "C:\ExportDir\Groups.csv"
foreach ($Group in $Groups) {
    Add-ADPrincipalGroupMembership -Identity $DestUser -MemberOf $Group
}
