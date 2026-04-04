
<#
.SYNOPSIS
    Manages active directory user group information.
#>

# Build an array of the objects you want to check here. Can be local paths, UNCs etc. Input method can be directly in the script as below, or imported from an external source.
$Paths = "\\computername.domain.com\directory"
# Create and initialize a new array for the output
$Output = @()
# Loop through each object in the array
foreach ($path in $paths){
    # Write some progress to the console so you know the script is working
    Write-Host "Processing $path"
    # Get the ACL for your first object. Ignore any unresolved SIDs, BUILTINs and other common identifiers.
    $ACLs = Get-Acl -path $path | Select-Object -ExpandProperty Access | Where-Object {$_.IdentityReference -notlike "*S-1-5-*"} | Where-Object {$_.IdentityReference -notlike "*BUILTIN*"} | Where-Object {$_.IdentityReference -notlike "*NT AUTHORITY*"} | Where-Object {$_.IdentityReference -notlike "Everyone"} | Select-Object IdentityReference,FileSystemRights
    # Loop through each entry returned by the Get-Acl command
    foreach ($ACL in $ACLs){
        # Convert the IdentityReference property to a string so it can be used with the next cmdlet
        $strObject = ($ACL.IdentityReference).ToString()
        # Find out what type of object it is. Result should only ever be a user or group
        $ACLobjectType = Get-ADObject $strObject | Select-Object -ExpandProperty Type
        # If it is a user, lets build a new object with the details we want
        if ($ACLobjectType -eq "user"){
            # Create a new System.Object
            $objResults = New-Object System.Object
            # Get AD user object information using Quest AD CMDlet
            $user = Get-ADUser -SizeLimit 0 $strObject | Select-Object SamAccountName,DisplayName,AccountisDisabled
            # Populate the results object with data
            $objResults | Add-Member -MemberType NoteProperty -Name "Name" -Value $user.samaccountname
            $objResults | Add-Member -MemberType NoteProperty -Name "Display Name" -Value $user.displayname
            $objResults | Add-Member -MemberType NoteProperty -Name "Object Type" -Value "User"
            $objResults | Add-Member -MemberType NoteProperty -Name "Membership Comes From" -Value "Direct"
            $objResults | Add-Member -MemberType NoteProperty -Name "Group Name" -Value "N/A"
            $objResults | Add-Member -MemberType NoteProperty -Name "Group Description" -Value "N/A"
            $objResults | Add-Member -MemberType NoteProperty -Name "Group Notes" -Value "N/A"
            $objResults | Add-Member -MemberType NoteProperty -Name "Permission" -Value $ACL.FileSystemRights
            $objResults | Add-Member -MemberType NoteProperty -Name "Path" -Value $path
            $objResults | Add-Member -MemberType NoteProperty -Name "disabled" -Value $user.accountisdisabled
            # Add the object data to the $Output array
            $Output += $objResults
            # Otherwise, the object is going to be a group
        }
        else {
            # So, get a list of the members of each group
            $groupmembers = Get-ADGroupMember -SizeLimit 0 $strObject | Select-Object SamAccountName,DisplayName,Type,AccountisDisabled
            # Also get some details for the group that can help identify what it is used for
            $groupdeets = Get-ADGroup $strObject | Select-Object Description,Notes
            # Loop through each group member and build an object similar to the one used for directly applied users above
            foreach ($member in $groupmembers) {
                $objResults = New-Object System.Object
                $objResults | Add-Member -MemberType NoteProperty -Name "Name" -Value $member.samaccountname
                $objResults | Add-Member -MemberType NoteProperty -Name "Display Name" -Value $member.displayname
                $objResults | Add-Member -MemberType NoteProperty -Name "Object Type" -Value $member.type
                $objResults | Add-Member -MemberType NoteProperty -Name "Membership Comes From" -Value "Group Member"
                $objResults | Add-Member -MemberType NoteProperty -Name "Group Name" -Value $strObject
                $objResults | Add-Member -MemberType NoteProperty -Name "Group Description" -Value $groupdeets.description
                $objResults | Add-Member -MemberType NoteProperty -Name "Group Notes" -Value $groupdeets.Notes
                $objResults | Add-Member -MemberType NoteProperty -Name "Permission" -Value $ACL.FileSystemRights
                $objResults | Add-Member -MemberType NoteProperty -Name "Path" -Value $path
                $objResults | Add-Member -MemberType NoteProperty -Name "disabled" -Value $member.accountisdisabled
                # Add the object data to the $Output array
                $Output += $objResults
            }
        }
    }
}
#--------------------Output-------------------#
$Output | Export-Csv C:\ExportDir\ADUserGroupInfo.csv -NoTypeInformation
