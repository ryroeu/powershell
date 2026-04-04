<#
.SYNOPSIS
Resets the Active Directory password for a specified user, forces a change at next logon,
and generates a random temporary password.

.DESCRIPTION
This script takes a username as input, generates a secure random password,
resets the user's AD password to this temporary password using an administrative reset,
and sets the 'User must change password at next logon' flag.
It provides feedback on success or failure and outputs the generated password.

.PARAMETER UserName
The SamAccountName (logon name) of the Active Directory user whose password needs resetting.

.EXAMPLE
.\Reset-ADUserPassword.ps1 -UserName jdoe

.NOTES
Date: 2025-04-02
Requires the Active Directory module for PowerShell.
Run with administrative privileges sufficient to reset user passwords in AD.
For PowerShell 7+: Ensure the Active Directory module is available in your environment
(e.g., via RSAT installation or running on a DC/management server).
#>
param(
    [Parameter(Mandatory=$true, HelpMessage="Enter the SamAccountName of the AD user.")]
    [string]$UserName
)

# Attempt to import the Active Directory module if not already loaded
# Suppress errors if it's already loaded or unavailable initially
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# Check if the required cmdlets are available after attempting import
if (-not (Get-Command Set-ADAccountPassword -ErrorAction SilentlyContinue) -or -not (Get-Command Set-ADUser -ErrorAction SilentlyContinue)) {
    Write-Error "The Active Directory PowerShell module is required and could not be loaded. Please ensure RSAT-AD-PowerShell tools are installed or run this script on a machine with the module."
    exit 1 # Exit if essential commands aren't found
}

try {
    # Generate a reasonably complex random password
    # Requires .NET Framework (System.Web is usually available)
    Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
    # Generate a 15-character password with at least 3 non-alphanumeric characters
    # Adjust length (15) and non-alphanumeric count (3) as needed per your policy
    $GeneratedPassword = [System.Web.Security.Membership]::GeneratePassword(15, 3)
    $NewSecurePassword = ConvertTo-SecureString -String $GeneratedPassword -AsPlainText -Force

    Write-Host "Attempting to reset password for user '$UserName'..."

    # Reset the account password using an administrative reset (-Reset)
    Set-ADAccountPassword -Identity $UserName -NewPassword $NewSecurePassword -Reset -ErrorAction Stop

    Write-Host "Password reset successful for '$UserName'."
    Write-Host "Setting 'User must change password at next logon' flag..."

    # Set the flag to force password change at the next logon
    Set-ADUser -Identity $UserName -ChangePasswordAtLogon $true -ErrorAction Stop

    Write-Host "Flag set successfully."
    Write-Host "--------------------------------------------------" -ForegroundColor Green
    Write-Host "SUCCESS: Password reset complete for user '$UserName'." -ForegroundColor Green
    Write-Host "Temporary Password: $GeneratedPassword"
    Write-Host "User MUST change this password at their next logon." -ForegroundColor Yellow
    Write-Host "--------------------------------------------------" -ForegroundColor Green

}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    # Specific error if the user doesn't exist
    Write-Error "Error: The user '$UserName' was not found in Active Directory."
}
catch {
    # Catch any other errors during the process
    Write-Error "An error occurred during the password reset process for '$UserName'."
    Write-Error "Error details: $($_.Exception.Message)"
    # Optional: Output the full error record for detailed debugging
    # Write-Error ($_.ToString())
}
finally {
    # Cleanup or final messages can go here if needed
    Write-Host "Script execution completed."
}
# End of script