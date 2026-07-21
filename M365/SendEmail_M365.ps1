#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users.Actions

<#
.SYNOPSIS
    Sends email through Microsoft Graph using delegated or application authentication.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Interactive')]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory, ParameterSetName = 'ClientSecret')]
    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$ClientId,

    [Parameter(Mandatory, ParameterSetName = 'ClientSecret')]
    [securestring]$ClientSecret,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$CertificateThumbprint,

    [Parameter(Mandatory)]
    [string]$SenderUserPrincipalName,

    [Parameter(Mandatory)]
    [mailaddress[]]$To,

    [mailaddress[]]$Cc,

    [Parameter(Mandatory)]
    [string]$Subject,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Body,

    [ValidateSet('Text', 'HTML')]
    [string]$BodyType = 'HTML',

    [string[]]$AttachmentPath,

    [bool]$SaveToSentItems = $true,

    [switch]$UseDeviceCode
)

$connectParameters = @{ TenantId = $TenantId; NoWelcome = $true }
switch ($PSCmdlet.ParameterSetName) {
    'ClientSecret' {
        $connectParameters.ClientSecretCredential = [pscredential]::new($ClientId, $ClientSecret)
    }
    'Certificate' {
        $connectParameters.ClientId = $ClientId
        $connectParameters.CertificateThumbprint = $CertificateThumbprint
    }
    default {
        $connectParameters.Scopes = 'Mail.Send'
        $connectParameters.UseDeviceCode = $UseDeviceCode
    }
}

$toRecipients = @($To | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address } } })
$ccRecipients = @($Cc | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address } } })
$attachments = @($AttachmentPath | ForEach-Object {
    $file = Get-Item -LiteralPath $_ -ErrorAction Stop
    $contentType = switch ($file.Extension.ToLowerInvariant()) {
        '.csv' { 'text/csv' }
        '.html' { 'text/html' }
        '.jpg' { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.png' { 'image/png' }
        '.pdf' { 'application/pdf' }
        '.txt' { 'text/plain' }
        '.xlsx' { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
        '.zip' { 'application/zip' }
        default { 'application/octet-stream' }
    }
    @{
        '@odata.type' = '#microsoft.graph.fileAttachment'
        Name          = $file.Name
        ContentType   = $contentType
        ContentBytes  = [Convert]::ToBase64String([IO.File]::ReadAllBytes($file.FullName))
    }
})

Connect-MgGraph @connectParameters | Out-Null
try {
    if ($PSCmdlet.ShouldProcess(($To.Address -join ', '), "Send Microsoft 365 email '$Subject'")) {
        $message = @{
            Subject      = $Subject
            Body         = @{ ContentType = $BodyType; Content = $Body }
            ToRecipients = $toRecipients
        }
        if ($ccRecipients.Count -gt 0) { $message.CcRecipients = $ccRecipients }
        if ($attachments.Count -gt 0) { $message.Attachments = $attachments }

        Send-MgUserMail -UserId $SenderUserPrincipalName -Message $message -SaveToSentItems:$SaveToSentItems
    }
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
