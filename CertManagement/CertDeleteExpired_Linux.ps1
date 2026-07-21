<#
.SYNOPSIS
(Linux) Finds and removes expired certificate FILES based on OpenSSL checks.

.DESCRIPTION
This script searches specified directories on a Linux system for common certificate file extensions (.pem, .crt, .cer).
It uses the 'openssl' command-line tool to check the expiration date of each certificate file found.
If a certificate file contains an expired certificate, the script can remove the FILE.
WARNING: This deletes the entire file. Use -WhatIf extensively.
WARNING: DO NOT target system-wide CA certificate directories like /etc/ssl/certs unless you fully understand the risks.

.PARAMETER SearchPath
An array of directory paths to search recursively for certificate files.
Defaults to '/etc/ssl/certs/' which might contain individual certs but also system certs - USE WITH CAUTION.
Consider more specific paths like '/etc/nginx/ssl', '/etc/apache2/ssl', '/home/user/certs'.

.PARAMETER Extensions
An array of file extensions to look for. Defaults to '.pem', '.crt', '.cer'.

.EXAMPLE
pwsh ./Remove-ExpiredCertificateFiles-Linux.ps1 -SearchPath '/etc/nginx/ssl/', '/srv/myapp/certs' -Verbose -WhatIf
Tests the removal of expired certificate files in specified Nginx and app directories with verbose output.

.EXAMPLE
sudo pwsh ./Remove-ExpiredCertificateFiles-Linux.ps1 -SearchPath '/etc/pki/tls/certs' -WhatIf
Carefully tests removal in a common RHEL/CentOS path. Ensure these are not managed system symlinks.

.NOTES
Date: 2025-04-02
Requires: PowerShell Core 7+, openssl command-line tool in PATH.
WARNING: Deleting certificate files can break applications relying on them. Verify paths and use -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess = $true)] # Enables -WhatIf, -Confirm
param(
    [Parameter(Mandatory = $false)]
    [string[]]$SearchPath = @("/etc/ssl/certs/"), # CAUTION with default - consider changing to safer app/user paths

    [Parameter(Mandatory = $false)]
    [string[]]$Extensions = @("*.pem", "*.crt", "*.cer")
)

# --- Configuration ---
# Path to the openssl executable (usually found in PATH)
$openSSLPath = "openssl"
# --- End Configuration ---

# Check if openssl command exists
try {
    Get-Command $openSSLPath -ErrorAction Stop | Out-Null
    Write-Verbose "Using '$openSSLPath' found in PATH."
}
catch {
    Write-Error "The '$openSSLPath' command was not found. Please install OpenSSL or ensure it's in your PATH."
    exit 1
}

$CurrentDate = Get-Date
Write-Verbose "Starting expired certificate file check at $CurrentDate"

$filesRemoved = 0
$filesFailed = 0
$filesSkipped = 0

foreach ($path in $SearchPath) {
    Write-Verbose "Searching for certificate files ($($Extensions -join ', ')) in '$path'..."
    if (-not (Test-Path -Path $path -PathType Container)) {
        Write-Warning "Search path '$path' not found or is not a directory. Skipping."
        continue
    }

    # Find files matching the extensions recursively
    # Use -File parameter to ensure we only get files
    $CertFiles = Get-ChildItem -Path $path -Recurse -File -Include $Extensions -ErrorAction SilentlyContinue

    if ($null -eq $CertFiles -or $CertFiles.Count -eq 0) {
        Write-Verbose "No certificate files matching extensions found in '$path'."
        continue
    }

    Write-Verbose "Found $($CertFiles.Count) potential certificate file(s) in '$path'."

    foreach ($File in $CertFiles) {
        $filePath = $File.FullName
        Write-Verbose "Checking file: $filePath"

        $opensslOutput = $null
        $errorMessage = $null
        $expiryDate = $null

        try {
            # Execute openssl to get the end date
            # Ignore stderr for now, check output validity
            $opensslOutput = & $openSSLPath x509 -in $filePath -noout -enddate -ErrorAction SilentlyContinue 2>&1

            # Basic check if openssl returned the expected line format
            if ($opensslOutput -match '^notAfter=(.+)') {
                $dateString = $Matches[1].Trim()
                try {
                    # Attempt to parse the date string (OpenSSL format e.g., "Apr  2 07:32:00 2024 GMT")
                    # PowerShell Core often handles common formats well
                     $expiryDate = Get-Date -Date $dateString
                     Write-Verbose " -> Extracted Expiry Date: $($expiryDate.ToString('yyyy-MM-dd HH:mm:ss'))"
                } catch {
                     Write-Warning "Could not parse date string '$dateString' from file '$filePath'. Error: $($_.Exception.Message)"
                     $errorMessage = "Date parsing failed"
                }
            } else {
                 # openssl might have failed (e.g., not a cert, password protected key file)
                 $errorMessage = "OpenSSL failed or file is not a valid certificate. Output/Error: $opensslOutput"
                 Write-Warning "Could not get valid expiry date for '$filePath'. $errorMessage"
            }
        } catch {
            $errorMessage = "Error executing openssl for '$filePath'. Error: $($_.Exception.Message)"
            Write-Warning $errorMessage
        }

        # Proceed only if we successfully got an expiry date
        if ($null -ne $expiryDate) {
            if ($expiryDate -lt $CurrentDate) {
                Write-Host "Expired certificate file found: '$filePath' (Expired: $($expiryDate.ToString('yyyy-MM-dd HH:mm:ss')))"

                if ($PSCmdlet.ShouldProcess("File: '$filePath'", "Remove Expired Certificate File")) {
                    try {
                        Remove-Item -Path $filePath -Force -ErrorAction Stop # -Force often needed for read-only files etc.
                        Write-Host "Successfully removed file: '$filePath'"
                        $filesRemoved++
                    } catch {
                        Write-Error "Failed to remove file '$filePath'. Error: $($_.Exception.Message)"
                        $filesFailed++
                    }
                } else {
                    Write-Host "Skipped removal (due to -WhatIf or user choice): '$filePath'"
                    $filesSkipped++
                }
            } else {
                 Write-Verbose " -> Certificate file is valid (Not Expired): '$filePath'"
            }
        } else {
             # File was likely not a valid cert or errored out
             $filesSkipped++
        }

    } # End foreach File
} # End foreach path

Write-Host "--------------------------------------------------"
Write-Host "Expired Certificate File Removal Summary (Linux):"
Write-Host "Files removed:          $filesRemoved"
Write-Host "Failed removals:      $filesFailed"
Write-Host "Files skipped/invalid:  $filesSkipped"
Write-Host "--------------------------------------------------"

# Optional: Keep window open logic (less common/useful on Linux terminals)
# if ($Host.Name -eq 'ConsoleHost') {
#     Read-Host -Prompt "Press Enter to exit"
# }
