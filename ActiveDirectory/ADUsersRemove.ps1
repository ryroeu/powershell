<#
.SYNOPSIS
    Reports and optionally removes inactive, expired, or disabled Active Directory users.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$SearchBase,

    [switch]$Inactive,

    [switch]$Expired,

    [switch]$Disabled,

    [ValidateRange(1, 3650)]
    [int]$InactiveDays = 90,

    [string]$ExportPath,

    [switch]$Remove
)

if (-not ($Inactive -or $Expired -or $Disabled)) {
    throw 'Specify at least one of -Inactive, -Expired, or -Disabled.'
}

$userMap = @{}
if ($Inactive) {
    foreach ($user in Search-ADAccount -SearchBase $SearchBase -AccountInactive -UsersOnly -TimeSpan ([timespan]::FromDays($InactiveDays))) {
        $userMap[$user.DistinguishedName] = $user
    }
}
if ($Expired) {
    foreach ($user in Search-ADAccount -SearchBase $SearchBase -AccountExpired -UsersOnly) {
        $userMap[$user.DistinguishedName] = $user
    }
}
if ($Disabled) {
    foreach ($user in Search-ADAccount -SearchBase $SearchBase -AccountDisabled -UsersOnly) {
        $userMap[$user.DistinguishedName] = $user
    }
}

$users = @($userMap.Values | ForEach-Object {
        Get-ADUser -Identity $_ -Properties PasswordExpired, PasswordNeverExpires, LastLogonDate
    })
$report = $users | Select-Object SamAccountName, Enabled, PasswordExpired, PasswordNeverExpires, LastLogonDate, DistinguishedName

if ($ExportPath) {
    $report | Export-Csv -LiteralPath $ExportPath -NoTypeInformation -Encoding utf8NoBOM
}
if ($Remove) {
    foreach ($user in $users) {
        if ($PSCmdlet.ShouldProcess($user.DistinguishedName, 'Remove Active Directory user')) {
            Remove-ADUser -Identity $user -Confirm:$false -ErrorAction Stop
        }
    }
}

$report
