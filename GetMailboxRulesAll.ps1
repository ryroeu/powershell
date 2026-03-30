$TenantID = 'YourTenantID'
$AppID = 'YourApplicationID'
$CertThumbprint = 'YourCertThumbprint'  # App must have Exchange.ManageAsApp permission
##############################

# Connect to Partner Center to get all customer tenants
Import-Module PartnerCenter
Connect-PartnerCenter -ApplicationId $AppID -TenantId $TenantID

$customers = Get-PartnerCustomer

$logs = foreach ($customer in $customers) {
    $startDate = (Get-Date).AddDays(-1)
    $endDate   = (Get-Date)

    # Connect to each customer tenant via delegated Exchange Online management
    Connect-ExchangeOnline -AppId $AppID -CertificateThumbprint $CertThumbprint `
        -Organization $customer.Domain -ShowBanner:$false

    if ((Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled -eq $false) {
        Write-Host "AuditLog is disabled for client $($customer.Name)"
    }

    $logsTenant = @()
    Write-Host "Retrieving logs for $($customer.Name)" -ForegroundColor Blue
    do {
        $logsTenant += Search-UnifiedAuditLog -SessionCommand ReturnLargeSet -SessionId $customer.Name `
            -ResultSize 5000 -StartDate $startDate -EndDate $endDate `
            -Operations "New-InboxRule", "Set-InboxRule", "UpdateInboxRules"
        Write-Host "Retrieved $($logsTenant.Count) logs" -ForegroundColor Yellow
    } while ($logsTenant.Count % 5000 -eq 0 -and $logsTenant.Count -ne 0)

    Write-Host "Finished retrieving logs" -ForegroundColor Green
    Disconnect-ExchangeOnline -Confirm:$false
    $logsTenant
}

foreach ($log in $logs) {
    $auditData = $log.AuditData | ConvertFrom-Json
    Write-Host "A new or changed rule has been found for user $($log.UserIds). The rule has the following info: $($auditData.Parameters | Out-String)`n"
}
if (!$logs) {
    Write-Host "Healthy."
}
