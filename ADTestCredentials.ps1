<#
.SYNOPSIS
    Tests Active Directory credentials.
#>

$UserName = 'UserName'
$Password = Read-Host "Enter your password: " -AsSecureString
Function Test-ADAuthentication {
    param($UserName,[SecureString] $Password)
    $null -ne (new-object directoryservices.directoryentry "",$UserName,$Password).PSBase.Name
}
Test-ADAuthentication $UserName $Password