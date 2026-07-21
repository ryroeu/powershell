<#
.SYNOPSIS
    Changes one Microsoft Entra user principal name with Microsoft Graph.
#>

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [string]$UserId,

    [Parameter(Mandatory)]
    [string]$NewUserPrincipalName
)

Connect-MgGraph -TenantId $TenantId -Scopes 'User.ReadWrite.All' -NoWelcome
try {
    if ($PSCmdlet.ShouldProcess($UserId, "Change UPN to '$NewUserPrincipalName'")) {
        Update-MgUser -UserId $UserId -UserPrincipalName $NewUserPrincipalName
        Get-MgUser -UserId $NewUserPrincipalName -Property Id, DisplayName, UserPrincipalName
    }
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
