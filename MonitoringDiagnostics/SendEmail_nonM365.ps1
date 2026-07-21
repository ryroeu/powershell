<#
.SYNOPSIS
    Sends an email through an SMTP server using the built-in .NET SMTP client.
.DESCRIPTION
    System.Net.Mail.SmtpClient remains available but is not recommended for new applications. Prefer a
    provider API or MailKit for new automation. This script exists for SMTP servers that still support it.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [mailaddress]$From,

    [Parameter(Mandatory)]
    [mailaddress[]]$To,

    [mailaddress[]]$Cc,

    [Parameter(Mandatory)]
    [string]$Subject,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Body,

    [string[]]$AttachmentPath,

    [Parameter(Mandatory)]
    [string]$SmtpServer,

    [ValidateRange(1, 65535)]
    [int]$Port = 587,

    [pscredential]$Credential,

    [switch]$UseSsl,

    [switch]$BodyAsHtml
)

$message = [Net.Mail.MailMessage]::new()
$client = [Net.Mail.SmtpClient]::new($SmtpServer, $Port)
try {
    $message.From = $From
    foreach ($address in $To) { $message.To.Add($address) }
    foreach ($address in $Cc) { $message.CC.Add($address) }
    $message.Subject = $Subject
    $message.Body = $Body
    $message.IsBodyHtml = $BodyAsHtml

    foreach ($path in $AttachmentPath) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Attachment '$path' was not found."
        }
        $message.Attachments.Add([Net.Mail.Attachment]::new((Resolve-Path -LiteralPath $path).Path))
    }

    $client.EnableSsl = $UseSsl
    if ($Credential) {
        $client.Credentials = $Credential.GetNetworkCredential()
    }

    if ($PSCmdlet.ShouldProcess(($To -join ', '), "Send email '$Subject' through $SmtpServer`:$Port")) {
        $client.Send($message)
    }
}
finally {
    $message.Dispose()
    $client.Dispose()
}
