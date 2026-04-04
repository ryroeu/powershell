<#
.SYNOPSIS
Finds and removes expired certificates from specified certificate stores.

.DESCRIPTION
This script searches for certificates within specified paths (defaulting to the Local Machine's Personal store)
whose expiration date (NotAfter property) is in the past. It provides options for verbose output,
testing the removal (-WhatIf), and forcing removal if confirmation prompts were implemented (though Remove-Item for certs usually doesn't prompt).

.PARAMETER StorePath
An array of paths to the certificate stores to search. Defaults to 'Cert:\LocalMachine\My'.
Use 'Cert:\CurrentUser\My' for the current user's personal store.

.EXAMPLE
.\Remove-ExpiredCertificates.ps1 -Verbose
Runs the script against the default store (LocalMachine\My) with detailed output.

.EXAMPLE
.\Remove-ExpiredCertificates.ps1 -StorePath 'Cert:\LocalMachine\My', 'Cert:\CurrentUser\My' -WhatIf
Tests the script against both the local machine and current user personal stores, showing what would be removed without actually deleting anything.

.EXAMPLE
.\Remove-ExpiredCertificates.ps1 -StorePath 'Cert:\LocalMachine\WebHosting'
Removes expired certificates specifically from the Web Hosting store on the local machine.

.NOTES
Date: 2025-04-02
Requires: PowerShell 5.1 or higher (including PowerShell Core 7+)
WARNING: Running this script without -WhatIf will permanently delete certificates. Ensure the StorePath is correctly specified.
         Avoid targeting sensitive stores like 'Root' or 'CA' unless you fully understand the consequences.
#>
[CmdletBinding(SupportsShouldProcess = $true)] # Enables -WhatIf, -Confirm
param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Path(s) to the certificate store(s) to search.")]
    [string[]]$StorePath = @("Cert:\LocalMachine\My") # Default to Local Machine Personal store - SAFER!
)

# Get the current date once for efficiency
$CurrentDate = Get-Date

Write-Verbose "Starting expired certificate check at $CurrentDate"
Write-Verbose "Searching in store(s): $($StorePath -join ', ')"

$certificatesRemoved = 0
$certificatesFailed = 0

# Process each specified store path
foreach ($path in $StorePath) {
    Write-Verbose "Processing store: $path"

    # Check if the path exists
    if (-not (Test-Path -Path $path)) {
        Write-Warning "Store path '$path' not found. Skipping."
        continue # Move to the next path in the loop
    }

    # Get certificates, filter for expired ones using the pipeline
    # Using -Recurse might be needed if subfolders exist within the specified store path, but often not necessary for standard stores like 'My'.
    # Add -Recurse if needed for your specific store structure.
    $ExpiredCerts = Get-ChildItem -Path $path | Where-Object { $_.PSIsContainer -eq $false -and $_.NotAfter -lt $CurrentDate }

    if ($null -eq $ExpiredCerts -or $ExpiredCerts.Count -eq 0) {
        Write-Verbose "No expired certificates found in '$path'."
        continue # Move to the next path
    }

    Write-Host "Found $($ExpiredCerts.Count) expired certificate(s) in '$path'."

    # Loop through the expired certificates found in the current path
    foreach ($Cert in $ExpiredCerts) {
        $subject = $Cert.Subject
        $thumbprint = $Cert.Thumbprint
        $expiryDate = $Cert.NotAfter.ToString("yyyy-MM-dd HH:mm:ss")
        $certIdentifier = "Subject='$subject', Thumbprint='$thumbprint', Expires='$expiryDate'"

        Write-Verbose "Attempting removal of: $certIdentifier"

        # $PSCmdlet.ShouldProcess checks for -WhatIf and -Confirm flags
        # Target: What is being changed
        # Action: What action is being performed
        if ($PSCmdlet.ShouldProcess($certIdentifier, "Remove Expired Certificate")) {
            try {
                # Use the certificate's specific path for removal
                Remove-Item -Path $Cert.PSPath -ErrorAction Stop
                Write-Host "Successfully removed: $certIdentifier"
                $certificatesRemoved++
            } catch {
                Write-Error "Failed to remove certificate '$thumbprint' ($subject) from '$path'. Error: $($_.Exception.Message)"
                $certificatesFailed++
            }
        } else {
             # This block executes if running with -WhatIf or if user chose 'No' on a -Confirm prompt (if one appeared)
             Write-Host "Skipped removal (due to -WhatIf or user choice): $certIdentifier"
        }
    } # End foreach Cert
} # End foreach path

Write-Host "--------------------------------------------------"
Write-Host "Expired Certificate Removal Summary:"
Write-Host "Successfully removed: $certificatesRemoved"
Write-Host "Failed removals:      $certificatesFailed"
Write-Host "--------------------------------------------------"

# Optional: Keep the window open if run directly outside of an existing PowerShell session
# Check if the host process is the console itself, not ISE or VSCode's integrated console etc.
# This might not be perfectly reliable in all environments but is a common approach.
if ($Host.Name -eq 'ConsoleHost' -and -not $env:VSCODE_PID) {
    Read-Host -Prompt "Press Enter to exit"
}