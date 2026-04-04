<#
.SYNOPSIS
Finds expired certificates on Linux by searching common directories 
and checking files with 'openssl'.
Requires PowerShell 7+ and the 'openssl' command-line tool.
May require 'sudo' to access all directories.
#>

# --- Configuration ---
# Add or remove directories as needed for your environment
$CertDirectoriesToSearch = @(
    "/etc/ssl/certs",
    "/etc/pki/tls/certs",
    "/etc/pki/ca-trust/extracted/pem",
    "/usr/local/share/ca-certificates",
    "/usr/share/ca-certificates"
    # Potentially add user directories if needed, e.g., "$HOME/.local/share/ca-certificates"
)
$CertExtensions = @("*.crt", "*.pem", "*.cer")
# --- End Configuration ---

# Check if openssl command exists
if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
    Write-Error "The 'openssl' command was not found. Please install OpenSSL and ensure it's in the PATH."
    exit 1
}

# Get the current date in UTC for comparison
$CurrentDateUTC = (Get-Date).ToUniversalTime()
$AllExpiredCerts = [System.Collections.Generic.List[PSObject]]::new()
$FilesChecked = 0
$TotalFiles = 0

Write-Host "Searching for certificate files in specified directories..." -ForegroundColor Yellow
Write-Host "Directories: $($CertDirectoriesToSearch -join ', ')"
Write-Host "Extensions: $($CertExtensions -join ', ')"

# Find potential certificate files
$PotentialCertFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
foreach ($dir in $CertDirectoriesToSearch) {
    if (Test-Path -Path $dir -PathType Container) {
        Write-Host "Searching in $dir..." -ForegroundColor Cyan
        try {
           $filesInDir = Get-ChildItem -Path $dir -Include $CertExtensions -Recurse -File -ErrorAction SilentlyContinue
           if($filesInDir){
               $PotentialCertFiles.AddRange($filesInDir)
           }
        } catch {
           Write-Warning "Error accessing or searching directory '$dir': $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Directory not found or not accessible: $dir"
    }
}

$TotalFiles = $PotentialCertFiles.Count
Write-Host "Found $TotalFiles potential certificate files. Analyzing with openssl..." -ForegroundColor Yellow

# Analyze each file
foreach ($file in $PotentialCertFiles) {
    $FilesChecked++
    Write-Progress -Activity "Analyzing Certificates" -Status "Processing '$($file.Name)' ($FilesChecked of $TotalFiles)" -PercentComplete (($FilesChecked / $TotalFiles) * 100)

    $opensslOutput = $null
    #$opensslError = $null
    $exitCode = 0

    try {
        # Use openssl to get end date and subject
        # -noout: Don't output the encoded cert
        # -enddate: Print the expiration date
        # -subject: Print the subject name
        # Handle potential errors from openssl
        $opensslOutput = openssl x509 -in $file.FullName -noout -enddate -subject -issuer -serial 2>&1
        $exitCode = $LASTEXITCODE
        
        # Check if openssl command itself produced an error message (stderr was redirected to stdout by 2>&1)
        if ($exitCode -ne 0 -or $opensslOutput -match 'unable to load certificate|error|Error') {
             # Silently continue if it's likely not a valid cert file or permission issue
             # Write-Warning "OpenSSL failed for '$($file.FullName)'. ExitCode: $exitCode Output: $opensslOutput"
             continue 
        }

        # Parse the output
        $notAfterString = ($opensslOutput | Select-String -Pattern 'notAfter=').Line -replace 'notAfter=' , ''
        $subjectString = ($opensslOutput | Select-String -Pattern 'subject=').Line -replace 'subject=' , ''
        $issuerString = ($opensslOutput | Select-String -Pattern 'issuer=').Line -replace 'issuer=' , ''
        $serialString = ($opensslOutput | Select-String -Pattern 'serial=').Line -replace 'serial=' , ''

        if (-not [string]::IsNullOrWhiteSpace($notAfterString)) {
            # Parse the date - OpenSSL usually outputs in 'MMM d HH:mm:ss yyyy GMT' format
            # Use ParseExact for specific format and treat as UTC
            try{
                 # Handle potential variations in spacing or month names if needed
                 $certExpiryDateUTC = [datetime]::ParseExact($notAfterString.Trim(), "MMM d HH:mm:ss yyyy 'GMT'", [System.Globalization.CultureInfo]::InvariantCulture).ToUniversalTime()
                 # Alternative format some versions might use: "MMM dd HH:mm:ss yyyy 'GMT'"
                 # $certExpiryDateUTC = [datetime]::ParseExact($notAfterString.Trim(), "MMM dd HH:mm:ss yyyy 'GMT'", [System.Globalization.CultureInfo]::InvariantCulture).ToUniversalTime()
            } catch {
                 Write-Warning "Could not parse date string '$notAfterString' for file '$($file.FullName)'"
                 continue # Skip if date parsing fails
            }

            # Compare dates
            if ($certExpiryDateUTC -lt $CurrentDateUTC) {
                 $AllExpiredCerts.Add(
                    [PSCustomObject]@{
                        Subject    = $subjectString.Trim()
                        NotAfter   = $certExpiryDateUTC.ToLocalTime() # Display in local time
                        FilePath   = $file.FullName
                        Issuer     = $issuerString.Trim()
                        Serial     = $serialString.Trim()
                    }
                 )
            }
        }
    } catch {
        # Catch any unexpected PowerShell errors during processing
        Write-Warning "Error processing file '$($file.FullName)': $($_.Exception.Message)"
    }
}
Write-Progress -Activity "Analyzing Certificates" -Completed

# --- Output Results ---
if ($AllExpiredCerts.Count -gt 0) {
    Write-Host "`nFound $($AllExpiredCerts.Count) expired certificate file(s):" -ForegroundColor Red
    $AllExpiredCerts | Format-Table -AutoSize -Wrap
} else {
    Write-Host "`nNo expired certificates found in the searched locations." -ForegroundColor Green
}

# --- End ---
# Keep the window open if run directly
if ($Host.Name -eq 'ConsoleHost') {
   Read-Host -Prompt "Press Enter to exit"
}