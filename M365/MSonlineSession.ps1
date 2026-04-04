<#
.SYNOPSIS
    Manages ms online session.
#>

Import-Module Microsoft.Graph.Authentication
$TenantID = "YourTenantID"
Connect-MgGraph -TenantId $TenantID -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
