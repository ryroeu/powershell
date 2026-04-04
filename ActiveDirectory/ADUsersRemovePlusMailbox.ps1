<#
.SYNOPSIS
    Manages active directory users remove plus mailbox.
#>

# The section below will be an input from Service Manager once the record has been approved for deletion
$AccountToBeDeleted = Read-Host -prompt "Account to be deleted...."
$deluser = Get-ADuser $AccountToBeDeleted 
$deleteuser = $deluser.name
# Display the user name and confirm that this is the account to be deleted
Write-Host
Write-Host "This is the user to be deleted" 
Write-Host
Write-Host $deleteuser -foregroundcolor "yellow"
Do {
    Write-Host "
    ---------- Delete User: ----------
    Y: Yes 	- Delete User'
    N: No 	- Exit'	
    ----------------------------------"
    $deleteuser = Read-Host -prompt "Select (Y/N) & press enter"
} until ($deleteuser -eq "Y" -or $deleteuser -eq "N")
# End section of manual section
if ($deleteuser -eq "Y"){
    $getdomaincontroller = Get-ADDomainController
    $domaincontrollername = $getdomaincontroller.name
    $profilescript = ('\\' + $domaincontrollername + '\' + 'NETLOGON\userscript' + '\') # You may need to change this dependent on the location of profiles in your organisation
    $userdatadirectory = "\\Fileshare\folder" 
    $userdirtodelete = ($userdatadirectory + $AccountToBeDeleted)
    Remove-Item -Recurse -Force $userdirtodelete -ErrorAction SilentlyContinue
    $userdatadirectory = "\\Fileshare\folder"
    $userdirtodelete = ($userdatadirectory + $AccountToBeDeleted)
    Remove-Item -Recurse -Force $userdirtodelete -ErrorAction SilentlyContinue
    # XML file to be deleted
    $xmlfiletodelete = ($profilescript + $AccountToBeDeleted + '.xml')
    Remove-Item $xmlfiletodelete
    #Mailbox section to be deleted
    Disable-Mailbox -identity $AccountToBeDeleted -confirm:$false
    Remove-ADUser -identity $AccountToBeDeleted -confirm:$false
    Write-Host "AD account, Profile folder, Profile deleted & Exchange mailbox disabled"
}
elseif ($deleteuser -eq "N"){
    exit
}