#Requires -Version 5.1 # Specify minimum PS version, 7+ recommended for best cross-platform compatibility

<#
.SYNOPSIS
Tests credential validity by attempting to connect and run a simple command on a list of remote computers.

.DESCRIPTION
Reads a list of computer names from a specified file.
Prompts for user credentials (username and password).
Attempts to execute a basic command ('hostname') on each remote computer using Invoke-Command and the provided credentials.
Reports success or failure for each computer.
Requires PowerShell Remoting (WinRM) to be enabled and configured on the target computers
and appropriate firewall rules to allow connections (typically TCP port 5985 for HTTP).

.PARAMETER ComputerListPath
The path to the text file containing the list of computer names (one per line). Defaults to '.\VMList.txt'.

.PARAMETER DefaultUserName
A default username (e.g., 'Domain\User') to suggest during the prompt. User can override it.

.EXAMPLE
.\Test-RemoteAuthentication.ps1

.EXAMPLE
.\Test-RemoteAuthentication.ps1 -ComputerListPath 'C:\Servers\ServerList.txt' -DefaultUserName 'CONTOSO\Admin'

.NOTES
Date:   2025-04-04
Ensure PowerShell Remoting (WinRM) is enabled on target machines.
The script tests the ability to execute commands remotely, which confirms authentication and authorization for remoting.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ComputerListPath = '.\VMList.txt',

    [Parameter(Mandatory=$false)]
    [string]$DefaultUserName = "$env:USERDOMAIN\$env:USERNAME" # Suggest current user as default
)

### --- Configuration --- ###

# Define the simple command to run remotely to test connection/authentication
$RemoteTestScriptBlock = {
    # You can change this to any simple command that indicates success
    hostname
    # Get-Date
    # $PSVersionTable.PSVersion
}

### --- Functions --- ###

function Test-RemoteMachineAuthentication {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerNames,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Verbose "Starting authentication tests..."

    foreach ($ComputerName in $ComputerNames) {
        # Trim potential whitespace from computer name read from file
        $CurrentComputer = $ComputerName.Trim()

        if ([string]::IsNullOrWhiteSpace($CurrentComputer)) {
            Write-Warning "Skipping blank line found in computer list."
            continue
        }

        Write-Host "Attempting to connect to '$CurrentComputer'..." -ForegroundColor Cyan

        try {
            # Attempt to run the command on the remote machine
            # ErrorAction Stop ensures that failures are caught by the Catch block
            $result = Invoke-Command -ComputerName $CurrentComputer `
                                     -Credential $Credential `
                                     -ScriptBlock $RemoteTestScriptBlock `
                                     -ErrorAction Stop `
                                     -Authentication Default # Or Negotiate, Kerberos, etc. if needed
                                     # -UseSSL # Add if WinRM is configured for HTTPS (Port 5986)
                                     # -SessionOption (New-PSSessionOption -OperationTimeoutSec 60) # Optional: Adjust timeout

            # If Invoke-Command succeeds without throwing an error:
            Write-Host " -> SUCCESS: Successfully authenticated and executed command on '$CurrentComputer'." -ForegroundColor Green
            # Display the command output
            Write-Host "    Remote Hostname: $result"

        }
        catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
            # Common errors: WinRM not running, firewall blocking, computer unreachable, authentication failure
            Write-Warning " -> FAILURE: Could not connect to or authenticate on '$CurrentComputer'. Error: $($_.Exception.Message)"
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
             # Catches pipeline stopping errors often wrapping underlying issues
             Write-Warning " -> FAILURE: Pipeline stopped during connection attempt to '$CurrentComputer'. Underlying Error: $($_.Exception.InnerException.Message)"
        }
        catch {
            # Catch any other unexpected errors
            Write-Error " -> FAILURE: An unexpected error occurred while testing '$CurrentComputer'. Error: $($_.Exception.Message)"
        }
    } # End foreach ComputerName
}

### --- Main Script --- ###

# --- Get Target Computer Names ---
try {
    Write-Verbose "Reading computer list from '$ComputerListPath'"
    $ComputerNames = Get-Content -Path $ComputerListPath -ErrorAction Stop
    if ($null -eq $ComputerNames -or $ComputerNames.Count -eq 0) {
         Write-Error "Computer list file '$ComputerListPath' is empty or could not be read properly."
         exit 1 # Exit if the list is effectively empty
    }
    Write-Host "Loaded $($ComputerNames.Count) computer names from '$ComputerListPath'."
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Error "Error: Computer list file not found at '$ComputerListPath'."
    exit 1 # Exit if file not found
}
catch {
    Write-Error "An unexpected error occurred while reading '$ComputerListPath': $($_.Exception.Message)"
    exit 1 # Exit on other read errors
}

# --- Get Credentials ---
Write-Host "Please enter the credentials to test."
$Credential = Get-Credential -UserName $DefaultUserName -Message "Enter credentials for remote authentication"

if ($null -eq $Credential) {
    Write-Error "Credential input cancelled or failed. Exiting."
    exit 1
}

Write-Host "Credentials obtained for user '$($Credential.UserName)'." -ForegroundColor Yellow
Write-Host ("-"*40) # Separator

# --- Run the Tests ---
# Use splatting for cleaner parameter passing
$TestParams = @{
    ComputerNames = $ComputerNames
    Credential    = $Credential
    Verbose       = $true # Enable verbose output within the function
}
Test-RemoteMachineAuthentication @TestParams

Write-Host ("-"*40) # Separator
Write-Host "Authentication testing complete." -ForegroundColor Green