<#
.SYNOPSIS
    Changes Microsoft Entra user principal names from a CSV file.
.DESCRIPTION
    The CSV must contain UserId and NewUserPrincipalName columns.
#>

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$Path
)

$changes = @(Import-Csv -LiteralPath $Path)
if (-not $changes) { throw "No records were found in '$Path'." }
foreach ($change in $changes) {
    if (-not $change.UserId -or -not $change.NewUserPrincipalName) {
        throw 'Every CSV record must contain UserId and NewUserPrincipalName.'
    }
}

Connect-MgGraph -TenantId $TenantId -Scopes 'User.ReadWrite.All' -NoWelcome
try {
    foreach ($change in $changes) {
        if ($PSCmdlet.ShouldProcess($change.UserId, "Change UPN to '$($change.NewUserPrincipalName)'")) {
            Update-MgUser -UserId $change.UserId -UserPrincipalName $change.NewUserPrincipalName
            [pscustomobject]@{
                UserId               = $change.UserId
                NewUserPrincipalName = $change.NewUserPrincipalName
                Updated              = $true
            }
        }
    }
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
