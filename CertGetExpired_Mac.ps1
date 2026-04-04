<#
.SYNOPSIS
Finds expired certificates on macOS using the 'security' command.
Requires PowerShell 7+.
#>

# Get the current date in UTC for comparison
$CurrentDateUTC = (Get-Date).ToUniversalTime()
$AllExpiredCerts = [System.Collections.Generic.List[PSObject]]::new()

Write-Host "Querying macOS Keychains for certificates..." -ForegroundColor Yellow

# Execute security command to dump all certificates in PEM format
try {
    # -a = all matching certs, -p = output PEM, -Z = include SHA256 hash (useful for thumbprint)
    $securityOutput = security find-certificate -a -p -Z
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to execute 'security find-certificate'. Exit code: $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Error "Error executing 'security find-certificate': $($_.Exception.Message)"
    exit 1
}

# Split the output into individual PEM certificate blocks using regex
# This looks for the BEGIN/END markers and captures everything in between, including the markers.
$pemBlocks = ($securityOutput | Out-String) -split '(?=-----BEGIN CERTIFICATE-----)' | Where-Object { $_ -match '-----BEGIN CERTIFICATE-----' }

Write-Host "Found $($pemBlocks.Count) potential certificate blocks. Analyzing..." -ForegroundColor Cyan

$count = 0
foreach ($pemBlock in $pemBlocks) {
    $count++
    Write-Progress -Activity "Analyzing Certificates" -Status "Processing block $count of $($pemBlocks.Count)" -PercentComplete (($count / $pemBlocks.Count) * 100)

    $cert = $null
    $certBytes = [System.Text.Encoding]::UTF8.GetBytes($pemBlock.Trim())

    try {
        # Create an X509Certificate2 object from the PEM data bytes
        # Use .NET directly as Import-Certificate might not handle raw PEM strings well cross-platform
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certBytes)

        # Compare expiry date (convert to UTC) with current date (already UTC)
        if ($cert.NotAfter.ToUniversalTime() -lt $CurrentDateUTC) {
            $AllExpiredCerts.Add(
                [PSCustomObject]@{
                    Subject    = $cert.Subject
                    Thumbprint = $cert.Thumbprint # SHA1 Hash
                    # SHA256 = $cert.GetCertHashString('SHA256') # Requires newer .NET method if available
                    NotAfter   = $cert.NotAfter
                    Issuer     = $cert.Issuer
                    Source     = "macOS Keychain (parsed)"
                }
            )
        }
    } catch {
        # Might fail if a block isn't a valid cert, etc.
        # Write-Warning "Could not process certificate block $count. Error: $($_.Exception.Message)"
        # Silently ignore malformed blocks for cleaner output
    } finally {
         # Clean up the cert object if created
        if ($null -ne $cert) {
            $cert.Dispose()
        }
    }
}
Write-Progress -Activity "Analyzing Certificates" -Completed

# --- Output Results ---
if ($AllExpiredCerts.Count -gt 0) {
    Write-Host "`nFound $($AllExpiredCerts.Count) expired certificate(s):" -ForegroundColor Red
    $AllExpiredCerts | Format-Table -AutoSize -Wrap
} else {
    Write-Host "`nNo expired certificates found in the Keychains via 'security' command." -ForegroundColor Green
}

# --- End ---
# Keep the window open if run directly
if ($Host.Name -eq 'ConsoleHost') {
   Read-Host -Prompt "Press Enter to exit"
}