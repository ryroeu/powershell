<#
.SYNOPSIS
Finds Active Directory user accounts with 'Password Never Expires' set,
optionally exports them to CSV, and optionally disables the setting for these users.

.DESCRIPTION
This script performs two main actions:
1. Identifies AD user accounts where the password is set to never expire.
2. Optionally exports the list of these users to a specified CSV file.
3. Optionally modifies these user accounts to disable the 'Password Never Expires' setting.

Requires the Active Directory PowerShell module (usually part of RSAT on Windows).
For PowerShell 7+ on Windows, ensure RSAT AD tools are installed. You might need
to run `Import-Module ActiveDirectory -UseWindowsPowerShell` if the native module fails.
This script will NOT run on non-Windows platforms using PowerShell Core.

.PARAMETER ExportPath
(Optional) Specifies the full path for the CSV export file.
If omitted, no CSV file will be created.
Example: C:\temp\PWNeverExpiresUsers.csv

.PARAMETER DisableNeverExpire
(Optional) If specified, the script will attempt to disable the 'Password Never Expires'
setting for the found users after confirmation (or immediately if -Force is used).
Defaults to $false (read-only mode).

.PARAMETER Force
(Optional) Used with -DisableNeverExpire. Suppresses the confirmation prompt before modifying users. Use with caution.

.EXAMPLE
.\Manage-PasswordNeverExpires.ps1 -Verbose
# Finds users but performs no export or changes (read-only). Shows verbose output.

.EXAMPLE
.\Manage-PasswordNeverExpires.ps1 -ExportPath "C:\ADReports\PWNeverExpires.csv" -Verbose
# Finds users, exports them to the specified CSV, but makes no changes.

.EXAMPLE
.\Manage-PasswordNeverExpires.ps1 -DisableNeverExpire -WhatIf
# Shows which users *would* have 'Password Never Expires' disabled, but makes no actual changes.

.EXAMPLE
.\Manage-PasswordNeverExpires.ps1 -ExportPath "C:\ADReports\PWNeverExpires.csv" -DisableNeverExpire -Verbose
# Finds users, exports them, prompts for confirmation, then disables the setting for confirmed users.

.EXAMPLE
.\Manage-PasswordNeverExpires.ps1 -DisableNeverExpire -Force -Verbose
# Finds users, disables the setting WITHOUT confirmation. Use with extreme caution!

.NOTES
Date:   2025-04-02
Ensure you have the necessary AD permissions to read user properties and modify them (if using -DisableNeverExpire).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string]$ExportPath,

    [Parameter(Mandatory = $false)]
    [switch]$DisableNeverExpire,

    [Parameter(Mandatory = $false)]
    [switch]$Force # Corresponds to -Confirm:$false
)

# --- Compatibility Check and Module Import ---
Write-Verbose "Checking for Active Directory module..."
$adModule = Get-Module -Name ActiveDirectory -ListAvailable
if (-not $adModule) {
    Write-Error "Active Directory PowerShell module not found. Please install RSAT: AD DS Tools."
    return # Exit script
}

# Attempt to import if not already loaded (useful for PS7+ compatibility layer if needed)
if (-not (Get-Command Search-ADAccount -ErrorAction SilentlyContinue)) {
    Write-Warning "Attempting to import Active Directory module. May require '-UseWindowsPowerShell' in PS7+."
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Verbose "Active Directory module imported successfully."
    }
    catch {
        Write-Error "Failed to import Active Directory module. Error: $($_.Exception.Message)"
        Write-Error "If using PowerShell 7+, try running 'Import-Module ActiveDirectory -UseWindowsPowerShell' manually first."
        return # Exit script
    }
}

# --- Main Logic ---
try {
    Write-Verbose "Searching for user accounts with PasswordNeverExpires set..."
    # Get the accounts and store them in a variable
    $usersToProcess = Search-ADAccount -PasswordNeverExpires -UsersOnly -ErrorAction Stop |
                      Select-Object -Property SamAccountName, Name, DistinguishedName, Enabled, PasswordExpired, PasswordNeverExpires, LastLogonDate

    if (-not $usersToProcess) {
        Write-Host "No user accounts found with 'Password Never Expires' set."
        return # Exit script
    }

    Write-Host "Found $($usersToProcess.Count) user account(s) with 'Password Never Expires' set."

    # --- Optional Export ---
    if ($PSBoundParameters.ContainsKey('ExportPath')) {
        if (-not $ExportPath) {
             Write-Warning "ExportPath parameter was specified but no path was provided. Skipping export."
        } else {
            Write-Verbose "Exporting user list to '$ExportPath'..."
            try {
                # Create directory if it doesn't exist
                $ExportDir = Split-Path -Path $ExportPath -Parent
                if (-not (Test-Path -Path $ExportDir)) {
                    Write-Verbose "Creating export directory: $ExportDir"
                    New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
                }
                $usersToProcess | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
                Write-Host "User list successfully exported to '$ExportPath'."
            }
            catch {
                Write-Error "Failed to export user list to '$ExportPath'. Error: $($_.Exception.Message)"
                # Decide if you want to stop processing or continue despite export failure
                # return
            }
        }
    }

    # --- Optional Modification ---
    if ($DisableNeverExpire) {
        Write-Host "`nProcessing users to disable 'Password Never Expires' setting..."

        foreach ($user in $usersToProcess) {
            $targetUser = $user.SamAccountName
            $targetObject = "User '$($user.Name)' (SAM: $targetUser)"

            # $PSCmdlet.ShouldProcess checks for -WhatIf and handles -Confirm/$Force
            if ($PSCmdlet.ShouldProcess($targetObject, "Disable Password Never Expires")) {
                Write-Verbose "Attempting to disable PasswordNeverExpires for user '$targetUser'..."
                try {
                    # Use the SamAccountName for reliable identification
                    Set-ADUser -Identity $targetUser -PasswordNeverExpires $false -ErrorAction Stop
                    Write-Verbose "Successfully disabled PasswordNeverExpires for user '$targetUser'."
                }
                catch {
                    Write-Error "Failed to disable PasswordNeverExpires for user '$targetUser'. Error: $($_.Exception.Message)"
                    # Continue to the next user
                }
            } else {
                 Write-Verbose "Skipping modification for user '$targetUser' due to WhatIf or user cancellation."
            }
        }
        Write-Host "Finished processing user modifications."
    } else {
         Write-Host "`nScript ran in read-only mode (no -DisableNeverExpire switch used). No changes were made."
    }

}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
   Write-Error "An AD Identity was not found during search or set operation. Error: $($_.Exception.Message)"
}
catch [Microsoft.ActiveDirectory.Management.ADServerDownException] {
   Write-Error "Cannot contact the Domain Controller. Check network connectivity and DC status. Error: $($_.Exception.Message)"
}
catch {
    # Catch any other terminating errors from Search-ADAccount or other parts
    Write-Error "An unexpected error occurred: $($_.Exception.Message)"
    Write-Error "Script execution halted."
}

Write-Host "`nScript completed."