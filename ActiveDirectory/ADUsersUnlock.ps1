<#
.SYNOPSIS
    Unlocks Active Directory users.
#>

### Export User Accounts to CSV for Reference ###
<#
.SYNOPSIS
Finds locked Active Directory user accounts, exports their details to a CSV file,
and optionally unlocks them with confirmation.

.DESCRIPTION
This script searches Active Directory for user accounts that are currently locked out.
It retrieves specified properties for these accounts and exports the list to a CSV file.
It then prompts the user whether to attempt unlocking these accounts.
Error handling is included for file operations and unlocking accounts.

.PARAMETER ExportPath
The full path, including filename, where the CSV report of locked users will be saved.
Defaults to a timestamped file in C:\Temp.

.PARAMETER ForceUnlock
Switch parameter. If specified, the script will attempt to unlock accounts without asking for confirmation. Use with caution.

.EXAMPLE
.\FindAndUnlockUsers.ps1

Searches for locked users, exports them to C:\Temp\LockedOutUsers_YYYYMMDD_HHMMSS.csv,
and asks for confirmation before unlocking.

.EXAMPLE
.\FindAndUnlockUsers.ps1 -ExportPath "C:\ADReports\LockedUsers_$(Get-Date -Format 'yyyy-MM-dd').csv"

Searches for locked users, exports them to the specified path, and asks for confirmation
before unlocking.

.EXAMPLE
.\FindAndUnlockUsers.ps1 -ForceUnlock

Searches for locked users, exports them to the default path, and immediately attempts
to unlock them without confirmation.

.NOTES
Requires the Active Directory PowerShell module.
On Windows: Ensure RSAT for Active Directory Domain Services is installed.
On PowerShell 7+ (Windows): The module should work if RSAT is installed.
On PowerShell 7+ (Linux/macOS or Windows without RSAT): You need to use PowerShell Remoting
to connect to a machine with the Active Directory module installed (e.g., a Domain Controller
or management server) and run the script there or use Implicit Remoting.

Ensure the user running the script has permissions to:
- Search Active Directory
- Write to the specified ExportPath
- Unlock AD user accounts
#>
#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess = $true)] # Adds -WhatIf and -Confirm support to Unlock-ADAccount implicitly
param(
    [Parameter(Mandatory = $false)]
    [string]$ExportPath = "C:\Temp\LockedOutUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",

    [Parameter(Mandatory = $false)]
    [switch]$ForceUnlock
)

# --- Configuration ---
$PropertiesToSelect = @(
    'SAMAccountName',
    'Enabled',
    'LockedOut', # Added LockedOut for confirmation in the report
    'PasswordExpired',
    'PasswordNeverExpires',
    'LastLogonDate'
)

# --- Script Body ---

Write-Host "Searching for locked out Active Directory user accounts..."

try {
    # Find locked out accounts ONCE and store them
    $LockedOutUsers = Search-ADAccount -UsersOnly -LockedOut -ErrorAction Stop | Get-ADUser -Properties $PropertiesToSelect -ErrorAction Stop
}
catch {
    Write-Error "Failed to search for locked out accounts. Error: $($_.Exception.Message)"
    # Exit if the search fails, as subsequent steps depend on it
    exit 1
}

# Check if any locked accounts were found
if ($null -eq $LockedOutUsers -or $LockedOutUsers.Count -eq 0) {
    Write-Host "No locked out user accounts found."
    # Exit gracefully if no users are found
    exit 0
}

Write-Host "Found $($LockedOutUsers.Count) locked out account(s)."

# --- Export to CSV ---
try {
    # Ensure the directory exists
    $DirectoryPath = Split-Path -Path $ExportPath -Parent
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Host "Creating directory: $DirectoryPath"
        New-Item -Path $DirectoryPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    Write-Host "Exporting list to $ExportPath..."
    $LockedOutUsers | Select-Object -Property $PropertiesToSelect | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop

    Write-Host "Export completed successfully."
}
catch {
    Write-Error "Failed to export locked out users to CSV. Path: $ExportPath. Error: $($_.Exception.Message)"
    # Optionally exit here, or continue to unlock attempt if desired
    # exit 1
}

# --- Unlock Accounts ---

# Decide whether to proceed with unlocking based on -ForceUnlock or user confirmation
$ProceedToUnlock = $false
if ($ForceUnlock.IsPresent) {
    Write-Host "'-ForceUnlock' specified. Proceeding to unlock accounts without confirmation."
    $ProceedToUnlock = $true
} else {
    # Ask for confirmation only if -WhatIf is not used
    if (-not $PSCmdlet.ShouldProcess("All $($LockedOutUsers.Count) found accounts", "Unlock")) {
         Write-Host "-WhatIf specified or user chose No. Skipping unlock operation."
         $ProceedToUnlock = $false # Ensure it's false if ShouldProcess returns false (user selects No)
    } else {
         # If -WhatIf was *not* used, ShouldProcess prompted and user said Yes (or -Confirm was used)
         $ProceedToUnlock = $true
    }

    # Redundant explicit confirmation if needed (usually ShouldProcess is sufficient)
    # $Confirmation = Read-Host "Do you want to attempt unlocking these $($LockedOutUsers.Count) accounts? (y/n)"
    # if ($Confirmation -eq 'y') {
    #     $ProceedToUnlock = $true
    # } else {
    #     Write-Host "Unlock operation cancelled by user."
    # }
}


if ($ProceedToUnlock) {
    Write-Host "Attempting to unlock accounts..."
    $UnlockSuccessCount = 0
    $UnlockFailCount = 0

    foreach ($User in $LockedOutUsers) {
        $SamAccount = $User.SAMAccountName
        try {
            # Use -WhatIf / -Confirm support from [CmdletBinding(SupportsShouldProcess = $true)]
            # If -WhatIf is used, this will only report the action
            # If -Confirm is used (and $ForceUnlock wasn't), it will prompt per user (unless user chose 'Yes to All' earlier)
             if ($PSCmdlet.ShouldProcess($SamAccount, "Unlock Account")) {
                 Unlock-ADAccount -Identity $User -ErrorAction Stop
                 Write-Host "Successfully unlocked account: $SamAccount"
                 $UnlockSuccessCount++
            } else {
                 Write-Host "Skipped unlocking account: $SamAccount (due to -WhatIf or user choice)"
            }
        }
        catch {
            Write-Warning "Failed to unlock account: $SamAccount. Error: $($_.Exception.Message)"
            $UnlockFailCount++
        }
    }

    Write-Host "Unlock operation summary: Success: $UnlockSuccessCount, Failed: $UnlockFailCount"
} else {
     # Message already printed if unlock was skipped
     if (-not $ForceUnlock.IsPresent -and -not $PSCmdlet.ShouldProcess("something", "something")) { # Check if it wasn't skipped due to -WhatIf
        Write-Host "Unlock operation skipped."
     }
}

Write-Host "Script finished."