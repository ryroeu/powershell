<#
.SYNOPSIS
    Retrieves mailbox rules single.
#>

$AppID           = 'YourApplicationID'
$CertThumbprint  = 'YourCertThumbprint'  # App must have Exchange.ManageAsApp permission
$ClientTenantName = "bla.onmicrosoft.com"
##############################

$startDate = (Get-Date).AddDays(-1)
$endDate   = (Get-Date)

# Connect to the target tenant via delegated Exchange Online management
Connect-ExchangeOnline -AppId $AppID -CertificateThumbprint $CertThumbprint `
    -Organization $ClientTenantName -ShowBanner:$false

if ((Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled -eq $false) {
    Write-Host "AuditLog is disabled for client $ClientTenantName"
}

$logsTenant = @()
Write-Host "Retrieving logs for $ClientTenantName" -ForegroundColor Blue
do {
    $logsTenant += Search-UnifiedAuditLog -SessionCommand ReturnLargeSet -SessionId $ClientTenantName `
        -ResultSize 5000 -StartDate $startDate -EndDate $endDate `
        -Operations "New-InboxRule", "Set-InboxRule", "UpdateInboxRules"
    Write-Host "Retrieved $($logsTenant.Count) logs" -ForegroundColor Yellow
} while ($logsTenant.Count % 5000 -eq 0 -and $logsTenant.Count -ne 0)

Write-Host "Finished retrieving logs" -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false

foreach ($log in $logsTenant) {
    $auditData = $log.AuditData | ConvertFrom-Json
    Write-Host "A new or changed rule has been found for user $($log.UserIds). The rule has the following info: $($auditData.Parameters | Out-String)`n"
}
if (!$logsTenant) {
    Write-Host "Healthy."
}
