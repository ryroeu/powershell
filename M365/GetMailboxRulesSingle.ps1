<#
.SYNOPSIS
    Retrieves inbox-rule change audit events for one Microsoft 365 organization.
#>

#Requires -Modules ExchangeOnlineManagement

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$AppId,

    [Parameter(Mandatory)]
    [string]$CertificateThumbprint,

    [datetime]$StartDate = (Get-Date).AddDays(-1),

    [datetime]$EndDate = (Get-Date)
)

if ($StartDate -ge $EndDate) { throw '-StartDate must be earlier than -EndDate.' }

Connect-ExchangeOnline -AppId $AppId -CertificateThumbprint $CertificateThumbprint -Organization $Organization -ShowBanner:$false
try {
    $sessionId = [guid]::NewGuid().ToString()
    $events = [Collections.Generic.List[object]]::new()
    do {
        $page = @(Search-UnifiedAuditLog -SessionCommand ReturnLargeSet -SessionId $sessionId -ResultSize 5000 `
                -StartDate $StartDate -EndDate $EndDate -Operations 'New-InboxRule', 'Set-InboxRule', 'UpdateInboxRules')
        foreach ($auditEvent in $page) {
            $auditData = $auditEvent.AuditData | ConvertFrom-Json
            $events.Add([pscustomobject]@{
                    Organization = $Organization
                    CreationDate = $auditEvent.CreationDate
                    UserId       = $auditEvent.UserIds
                    Operation    = $auditEvent.Operations
                    ResultStatus = $auditEvent.ResultStatus
                    Parameters   = $auditData.Parameters
                    AuditData    = $auditData
                })
        }
    } while ($page.Count -eq 5000)

    $events
}
finally {
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}
