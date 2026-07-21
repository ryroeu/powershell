<#
.SYNOPSIS
    Sets Active Directory home-directory paths for selected users.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$HomeDirectoryRoot,

    [ValidatePattern('^[A-Za-z]:$')]
    [string]$HomeDrive = 'H:',

    [string]$SearchBase,

    [string[]]$Identity
)

$users = if ($Identity) {
    $Identity | ForEach-Object { Get-ADUser -Identity $_ }
}
else {
    $parameters = @{ Filter = '*' }
    if ($SearchBase) { $parameters.SearchBase = $SearchBase }
    Get-ADUser @parameters
}

foreach ($user in $users) {
    $homeDirectory = Join-Path $HomeDirectoryRoot $user.SamAccountName
    if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Set home directory to '$homeDirectory'")) {
        Set-ADUser -Identity $user -HomeDirectory $homeDirectory -HomeDrive $HomeDrive
    }
}
