<#
.SYNOPSIS
Sets the Default Domain Password Policy for a specified Active Directory domain or the current user's domain.

.DESCRIPTION
This script configures various settings for the Default Domain Password Policy,
including lockout behavior, password complexity, age, length, and reversible encryption.
It requires the Active Directory PowerShell module (available via RSAT on Windows).

.PARAMETER DomainName
The DNS name of the target domain (e.g., 'fabrikam.com').
If not specified, the script uses the domain of the currently logged-on user.

.PARAMETER LockoutDuration
Specifies the length of time that an account is locked after the number of failed logon attempts exceeds the threshold.
Format: Days.Hours:Minutes:Seconds (e.g., '0.00:40:00' for 40 minutes). Default: '0.00:40:00'.

.PARAMETER LockoutObservationWindow
Specifies the maximum time interval between failed logon attempts before the counter resets.
Format: Days.Hours:Minutes:Seconds (e.g., '0.00:20:00' for 20 minutes). Default: '0.00:20:00'.

.PARAMETER LockoutThreshold
Specifies the number of failed logon attempts that causes a user account to be locked out. Default: 5.
(Note: Default Domain Policy cannot have a threshold of 0 unless LockoutDuration is also 0)

.PARAMETER MaxPasswordAge
Specifies the maximum length of time that a user can have the same password.
Format: Days.Hours:Minutes:Seconds (e.g., '90.00:00:00' for 90 days). Default: '42.00:00:00'.

.PARAMETER MinPasswordAge
Specifies the minimum length of time that a user must keep a password before changing it.
Format: Days.Hours:Minutes:Seconds (e.g., '1.00:00:00' for 1 day). Default: '1.00:00:00'.

.PARAMETER MinPasswordLength
Specifies the minimum number of characters required in a password. Default: 12.

.PARAMETER PasswordHistoryCount
Specifies the number of previous passwords to save. Users cannot reuse saved passwords. Default: 24.

.PARAMETER ComplexityEnabled
Specifies whether password complexity rules are enabled ($true) or disabled ($false). Default: $true.

.PARAMETER ReversibleEncryptionEnabled
Specifies whether reversible encryption is enabled ($true) or disabled ($false). Default: $false (Recommended).

.EXAMPLE
PS C:\> .\Set-DomainPasswordPolicy.ps1 -Verbose

Sets the password policy for the current user's domain using default values (prompts for confirmation).

.EXAMPLE
PS C:\> .\Set-DomainPasswordPolicy.ps1 -DomainName 'contoso.com' -MinPasswordLength 14 -MaxPasswordAge '60.00:00:00' -Verbose

Sets the password policy for 'contoso.com', overriding the minimum password length and maximum password age,
providing verbose output and prompting for confirmation.

.EXAMPLE
PS C:\> .\Set-DomainPasswordPolicy.ps1 -DomainName 'fabrikam.com' -LockoutThreshold 10 -Confirm:$false -Verbose

Sets the password policy for 'fabrikam.com', overriding the lockout threshold, suppressing the confirmation prompt,
and providing verbose output.

.NOTES
Requires the Active Directory PowerShell module. Install RSAT for AD DS on Windows.
Run with Administrator privileges, typically Domain Admin or equivalent rights to modify domain policy.
Consider your organization's security policies before changing these settings.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string]$DomainName,

    [Parameter(Mandatory = $false)]
    [TimeSpan]$LockoutDuration = '00:40:00', # 40 minutes

    [Parameter(Mandatory = $false)]
    [TimeSpan]$LockoutObservationWindow = '00:20:00', # 20 minutes

    [Parameter(Mandatory = $false)]
    [int]$LockoutThreshold = 5, # Default is often 0 in Get-, but setting requires non-zero if duration > 0. 5 is common.

    [Parameter(Mandatory = $false)]
    [TimeSpan]$MaxPasswordAge = '42.00:00:00', # 42 days (Windows Default)

    [Parameter(Mandatory = $false)]
    [TimeSpan]$MinPasswordAge = '1.00:00:00', # 1 day (Windows Default)

    [Parameter(Mandatory = $false)]
    [int]$MinPasswordLength = 12, # Increased from Windows Default (7)

    [Parameter(Mandatory = $false)]
    [int]$PasswordHistoryCount = 24, # Windows Default

    [Parameter(Mandatory = $false)]
    [bool]$ComplexityEnabled = $true, # Windows Default

    [Parameter(Mandatory = $false)]
    [bool]$ReversibleEncryptionEnabled = $false # Windows Default
)

# Check if the Active Directory module is available
Write-Verbose "Checking for Active Directory module..."
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "Active Directory PowerShell module not found. Please install Remote Server Administration Tools (RSAT) for AD DS."
    return
}

# Import the module if not already loaded (optional, often auto-loads)
# Import-Module ActiveDirectory -ErrorAction Stop

# Determine the target domain identity
$TargetIdentity = $null
if ([string]::IsNullOrWhiteSpace($DomainName)) {
    try {
        Write-Verbose "No DomainName specified, attempting to determine current domain..."
        # Get the FQDN (DNS Root) of the current domain
        $CurrentDomain = (Get-ADDomain -ErrorAction Stop).DNSRoot
        $TargetIdentity = $CurrentDomain
        Write-Verbose "Targeting current domain: $TargetIdentity"
    }
    catch {
        Write-Error "Could not automatically determine the current domain. Please specify -DomainName. Error: $($_.Exception.Message)"
        return
    }
}
else {
    $TargetIdentity = $DomainName
    Write-Verbose "Targeting specified domain: $TargetIdentity"
}

# Define parameters for Set-ADDefaultDomainPasswordPolicy using Splatting
$policyParams = @{
    Identity                   = $TargetIdentity
    LockoutDuration            = $LockoutDuration
    LockoutObservationWindow   = $LockoutObservationWindow
    LockoutThreshold           = $LockoutThreshold
    ComplexityEnabled          = $ComplexityEnabled
    ReversibleEncryptionEnabled = $ReversibleEncryptionEnabled
    MinPasswordLength          = $MinPasswordLength
    MinPasswordAge             = $MinPasswordAge
    MaxPasswordAge             = $MaxPasswordAge
    PasswordHistoryCount       = $PasswordHistoryCount
    ErrorAction                = 'Stop' # Make errors terminating within the Try block
    Verbose                    = $PSBoundParameters.ContainsKey('Verbose') # Pass Verbose preference
}

# Check if the operation should proceed (handles -WhatIf and -Confirm)
if ($PSCmdlet.ShouldProcess($TargetIdentity, "Set Default Domain Password Policy")) {
    try {
        Write-Verbose "Applying password policy settings to domain '$TargetIdentity'..."
        # Execute the command with splatted parameters
        Set-ADDefaultDomainPasswordPolicy @policyParams
        Write-Host "Successfully updated Default Domain Password Policy for '$TargetIdentity'."
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Error "Domain '$TargetIdentity' not found or could not be contacted. Verify the DomainName."
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "Permission denied. Ensure you have sufficient rights (e.g., Domain Admins) to modify the password policy for '$TargetIdentity'."
    }
    catch {
        # Catch any other errors
        Write-Error "An unexpected error occurred while setting password policy for '$TargetIdentity': $($_.Exception.Message)"
        Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
        # Optional: Uncomment to see full error details
        # Write-Error $_.ScriptStackTrace
    }
}
else
{
    Write-Warning "Operation cancelled by user or -WhatIf specified."
}

Write-Verbose "Script finished."