<#
.SYNOPSIS
    Removes application 4 non admins.
#>

# Get local users
$Users = Get-LocalUser | Select-Object Name
# Get members of administrators group
$Admins = Get-LocalGroupMember -Name Administrators | Select-Object Name
# Set the AppXPackage Name
$App = "Name of AppXPackage"
# Check to see if this user is an administrator and act accordingly
foreach ($User in $Users) {
    if ($Admins -Contains $User) {
        Write-Host "$User is NOT a local administrator" -ForegroundColor Green
        # Remove the app
        Get-AppXPackage -User $User -Name $App | Remove-AppxPackage
    } 
    else {
        Write-Host "$User is a local administrator" -ForegroundColor Red
    }
}