<#
.SYNOPSIS
    Reports and optionally moves inactive, expired, and disabled Active Directory users.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$SearchBase,

    [Parameter(Mandatory)]
    [string]$InactiveTargetPath,

    [Parameter(Mandatory)]
    [string]$ExpiredTargetPath,

    [Parameter(Mandatory)]
    [string]$DisabledTargetPath,

    [ValidateRange(1, 3650)]
    [int]$InactiveDays = 90,

    [string]$ExportDirectory,

    [switch]$Move
)

$categories = @(
    @{ Name = 'Inactive'; TargetPath = $InactiveTargetPath; Users = @(Search-ADAccount -SearchBase $SearchBase -AccountInactive -UsersOnly -TimeSpan ([timespan]::FromDays($InactiveDays))) },
    @{ Name = 'Expired'; TargetPath = $ExpiredTargetPath; Users = @(Search-ADAccount -SearchBase $SearchBase -AccountExpired -UsersOnly) },
    @{ Name = 'Disabled'; TargetPath = $DisabledTargetPath; Users = @(Search-ADAccount -SearchBase $SearchBase -AccountDisabled -UsersOnly) }
)

# The later category wins when an account meets more than one condition: Disabled, then Expired, then Inactive.
$assignments = @{}
foreach ($category in $categories) {
    foreach ($user in $category.Users) {
        $assignments[$user.DistinguishedName] = [pscustomobject]@{
            Category   = $category.Name
            TargetPath = $category.TargetPath
            User       = $user
        }
    }
}

$report = foreach ($assignment in $assignments.Values) {
    $user = Get-ADUser -Identity $assignment.User -Properties PasswordExpired, PasswordNeverExpires, LastLogonDate
    [pscustomobject]@{
        Category            = $assignment.Category
        SamAccountName      = $user.SamAccountName
        Enabled             = $user.Enabled
        PasswordExpired     = $user.PasswordExpired
        PasswordNeverExpires = $user.PasswordNeverExpires
        LastLogonDate       = $user.LastLogonDate
        DistinguishedName   = $user.DistinguishedName
        TargetPath          = $assignment.TargetPath
    }
}

if ($ExportDirectory) {
    New-Item -ItemType Directory -Path $ExportDirectory -Force | Out-Null
    foreach ($categoryName in 'Inactive', 'Expired', 'Disabled') {
        $report | Where-Object Category -eq $categoryName |
            Export-Csv -LiteralPath (Join-Path $ExportDirectory "$categoryName`Users.csv") -NoTypeInformation -Encoding utf8NoBOM
    }
}

if ($Move) {
    foreach ($assignment in $assignments.Values) {
        if ($PSCmdlet.ShouldProcess($assignment.User.DistinguishedName, "Move to '$($assignment.TargetPath)'")) {
            Move-ADObject -Identity $assignment.User -TargetPath $assignment.TargetPath -ErrorAction Stop
        }
    }
}

$report | Sort-Object Category, SamAccountName
