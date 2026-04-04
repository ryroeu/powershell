<#
.SYNOPSIS
    Manages cert get expired windows.
#>

# Get the current date once for comparison
$CurrentDate = Get-Date

# --- Find Expired Certificates in LocalMachine Store ---
Write-Host "Checking LocalMachine certificate store..." -ForegroundColor Yellow

# Get certificates, filter for expired ones, and select specific properties
$ExpiredCertsLocalMachine = Get-ChildItem -Path Cert:\LocalMachine\ -Recurse | Where-Object { $_.NotAfter -lt $CurrentDate } | Select-Object -Property Subject, Thumbprint, NotAfter, @{Name='Store';Expression={'LocalMachine'}}

# Output the results, if any
if ($ExpiredCertsLocalMachine) {
    Write-Host "Found expired certificates in LocalMachine:" -ForegroundColor Red
    $ExpiredCertsLocalMachine | Format-Table -AutoSize
} else {
    Write-Host "No expired certificates found in LocalMachine." -ForegroundColor Green
}

# --- (Optional) Find Expired Certificates in CurrentUser Store ---
# Uncomment the following block if you want to check the CurrentUser store as well

# Write-Host "`nChecking CurrentUser certificate store..." -ForegroundColor Yellow
# $ExpiredCertsCurrentUser = Get-ChildItem -Path Cert:\CurrentUser\ -Recurse | Where-Object { $_.NotAfter -lt $CurrentDate } | Select-Object -Property Subject, Thumbprint, NotAfter, @{Name='Store';Expression={'CurrentUser'}}
#
# if ($ExpiredCertsCurrentUser) {
#     Write-Host "Found expired certificates in CurrentUser:" -ForegroundColor Red
#     $ExpiredCertsCurrentUser | Format-Table -AutoSize
# } else {
#     Write-Host "No expired certificates found in CurrentUser." -ForegroundColor Green
# }

# --- End ---

# Keep the window open if run directly
Read-Host -Prompt "Press Enter to exit"