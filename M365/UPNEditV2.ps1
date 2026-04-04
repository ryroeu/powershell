<#
.SYNOPSIS
    Manages upn edit v 2.
#>

Import-Module Microsoft.Graph.Users
$TenantID = "YourTenantID"
Connect-MgGraph -TenantId $TenantID -Scopes "User.ReadWrite.All"
Update-MgUser -UserId "Username@domain.onmicrosoft.com" -UserPrincipalName "Username@domain.com"
