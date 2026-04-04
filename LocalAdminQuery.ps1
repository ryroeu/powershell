# Get who I am
$Me = whoami.exe
# Get members of administrators group
$Admins = Get-LocalGroupMember -Name Administrators | Select-Object Name
# Check to see if this user is an administrator and act accordingly
if ($Admins -Contains $Me) {
    Write-Host "$Me is a local administrator" -ForegroundColor Green
}
else {
    Write-Host "$Me is NOT a local administrator" -ForegroundColor Red
}