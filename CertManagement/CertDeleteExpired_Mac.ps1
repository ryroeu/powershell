<#
.SYNOPSIS
(macOS) Finds expired certificates in Keychains using the 'security' tool.

.DESCRIPTION
This script uses the macOS 'security' command-line tool to find certificates in all accessible Keychains.
It parses the output to identify certificates whose expiration date is in the past.
WARNING: This script DOES NOT automatically delete certificates due to complexity and risk.
It REPORTS expired certificates and provides the manual 'security delete-certificate' command format.
Manual verification using Keychain Access application is recommended before deleting.

.PARAMETER CheckLoginKeychain
Include the user's login keychain in the search. Defaults to $true.

.PARAMETER CheckSystemKeychain
Include the system keychain (/Library/Keychains/System.keychain) in the search. Requires admin rights usually. Defaults to $true.

.EXAMPLE
pwsh ./Find-ExpiredCerts-macOS.ps1 -Verbose
Finds expired certificates in login and system keychains with detailed output.

.EXAMPLE
sudo pwsh ./Find-ExpiredCerts-macOS.ps1 -CheckSystemKeychain $true -CheckLoginKeychain $false
Finds expired certificates only in the system keychain (requires sudo).

.NOTES
Date: 2025-04-02
Requires: PowerShell Core 7+, macOS operating system, 'security' command-line tool.
INFO: Deletion is a manual process using the output provided. Verify Common Name and SHA-1 Hash.
#>
[CmdletBinding()] # No ShouldProcess needed as we are not deleting automatically
param(
    [Parameter(Mandatory = $false)]
    [bool]$CheckLoginKeychain = $true,

    [Parameter(Mandatory = $false)]
    [bool]$CheckSystemKeychain = $true
)

# --- Configuration ---
$securityPath = "/usr/bin/security"
# --- End Configuration ---

if (-not (Test-Path $securityPath)) {
    Write-Error "'$securityPath' not found. This script is only for macOS."
    exit 1
}

$CurrentDate = Get-Date
Write-Verbose "Starting expired certificate check on macOS Keychains at $CurrentDate"

$expiredCertsFound = @()
$keychainsToSearch = @()

if ($CheckLoginKeychain) { $keychainsToSearch += $null } # null or omitting -k searches default/login keychain
if ($CheckSystemKeychain) { $keychainsToSearch += "/Library/Keychains/System.keychain" }

if ($keychainsToSearch.Count -eq 0) {
     Write-Warning "No keychains selected for searching."
     exit 0
}

Write-Verbose "Searching Keychains: $(if ($CheckLoginKeychain) {'Login/Default Keychain '})$(if ($CheckSystemKeychain) {'System Keychain '})"

foreach ($keychain in $keychainsToSearch) {
    $keychainArg = if ($null -ne $keychain) { @("-k", $keychain) } else { @() }
    $keychainName = if ($null -ne $keychain) { $keychain } else { "Login/Default" }
    Write-Verbose "Checking Keychain: $keychainName"

    # Use find-certificate to get basic info (Common Name, SHA-1 hash)
    # We need the hash later for potential deletion and precise identification
    # Redirect stderr to check for errors (like permission denied on System keychain without sudo)
    $findCertOutput = & $securityPath find-certificate -a -Z @keychainArg 2>&1

    # Check for common errors
     if ($findCertOutput -match 'Could not open keychain') {
          Write-Warning "Could not open keychain '$keychainName'. Permission denied? Try running with sudo for System Keychain."
          continue
     }
      if ($findCertOutput -match 'security: SecKeychain') { # Other potential errors
          Write-Warning "Error interacting with keychain '$keychainName'. Output: $($findCertOutput -join '; ')"
          continue
      }

    # Process the output line by line
    # Sample Output Lines:
    # key pair "...."
    # certificate "...."
    # SHA-1 hash: 7F9.................
    #       "alis"<blob>="Common Name Here"       <== This is the alis field (Subject Common Name)
    #       "labl"<blob>="Common Name Here"       <== Sometimes labl is used

    $currentHash = $null
    $currentCommonName = $null

    foreach ($line in $findCertOutput) {
        if ($line -match 'SHA-1 hash:\s*([A-Fa-f0-9]+)') {
            $currentHash = $Matches[1]
            $currentCommonName = $null # Reset CN for the new cert block
        } elseif (($line -match '"alis"<blob>="([^"]+)"' -or $line -match '"labl"<blob>="([^"]+)"') -and $null -ne $currentHash) {
             # Prefer 'alis' but take 'labl' if 'alis' wasn't found for this hash yet
             if ($null -eq $currentCommonName) {
                $currentCommonName = $Matches[1]

                # Now we have Hash and CN, get the detailed info including expiry for this specific cert
                Write-Verbose " -> Found Cert: CN='$currentCommonName', Hash='$currentHash'. Checking expiry..."
                $certDetailsOutput = & $securityPath find-certificate -a -Z $currentHash -p @keychainArg | & openssl x509 -noout -enddate -inform PEM 2>&1

                if ($certDetailsOutput -match '^notAfter=(.+)') {
                    $dateString = $Matches[1].Trim()
                    try {
                        $expiryDate = Get-Date -Date $dateString
                        Write-Verbose "    -> Expiry Date: $($expiryDate.ToString('yyyy-MM-dd HH:mm:ss'))"
                        if ($expiryDate -lt $CurrentDate) {
                            Write-Host ("Expired Certificate Found in Keychain '{0}'!" -f $keychainName) -ForegroundColor Yellow
                            Write-Host "  Common Name: $currentCommonName"
                            Write-Host "  SHA-1 Hash : $currentHash"
                            Write-Host "  Expires    : $($expiryDate.ToString('yyyy-MM-dd HH:mm:ss'))"

                            # Construct the manual deletion command
                            $deleteCmd = "$securityPath delete-certificate -Z $currentHash"
                             # Add keychain path if not default/login
                             if ($null -ne $keychain) { $deleteCmd += " -k '$keychain'" }
                             # Add sudo if checking system keychain
                             if ($CheckSystemKeychain -and $keychain -eq "/Library/Keychains/System.keychain") { $deleteCmd = "sudo " + $deleteCmd}

                            Write-Host "  To delete manually, verify details and run:"
                            Write-Host "    $deleteCmd" -ForegroundColor Cyan
                            Write-Host ""
                            $expiredCertsFound += [PSCustomObject]@{
                                Keychain    = $keychainName
                                CommonName  = $currentCommonName
                                Hash        = $currentHash
                                Expires     = $expiryDate
                                DeleteCmd   = $deleteCmd
                            }
                        }
                    } catch {
                        Write-Warning "Could not parse date string '$dateString' for cert CN='$currentCommonName', Hash='$currentHash'. Error: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "Could not get expiry date using openssl for cert CN='$currentCommonName', Hash='$currentHash'. Output: $certDetailsOutput"
                }
                # Reset hash/CN for next cert block in find-certificate output
                 $currentHash = $null
                 $currentCommonName = $null
             }
        } elseif ($line -match 'key pair|certificate "') {
             # Start of a new item, reset hash/cn if they weren't processed
             $currentHash = $null
             $currentCommonName = $null
        }
    }# End foreach line
} # End foreach keychain

Write-Host "--------------------------------------------------"
Write-Host "Expired Certificate Check Summary (macOS):"
if ($expiredCertsFound.Count -gt 0) {
    Write-Host "Found $($expiredCertsFound.Count) expired certificate(s)."
    Write-Host "Review the details above. Deletion is a MANUAL process using the provided commands."
    Write-Host "RECOMMENDED: Verify certificates in the 'Keychain Access' application before deleting."
} else {
    Write-Host "No expired certificates found in the searched keychains."
}
Write-Host "--------------------------------------------------"

# Output the objects if needed for further scripting
# return $expiredCertsFound