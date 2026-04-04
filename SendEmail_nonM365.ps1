<#
.SYNOPSIS
    Sends email non Microsoft 365.
#>

# --- Configuration ---
$From = "user@domain.com"
$To = "recipient@domain.com"
$Cc = "cc-user@domain.com"
$AttachmentPath = "C:\Temp\File.jpg"
$Subject = "File Request (.NET SmtpClient)"
$Body = "<h2>Here is the file you requested</h2><br><br>"
$Body += "Name of file: $(Split-Path -Path $AttachmentPath -Leaf)"

$SMTPServer = "smtp.mailserver.com"
$SMTPPort = 587

# --- Credentials (Handle Securely in production!) ---
Write-Host "Please enter SMTP credentials for $SMTPServer..."
$Credential = Get-Credential # Use PSCredential object

# --- Create Mail Objects ---
# IMPORTANT: Using a class Microsoft discourages for new development.
Write-Warning "Using System.Net.Mail.SmtpClient, which is not recommended by Microsoft for new development."

$mailMessage = New-Object System.Net.Mail.MailMessage
$mailMessage.From = $From
$mailMessage.To.Add($To)
if ($Cc) { $mailMessage.CC.Add($Cc) }
$mailMessage.Subject = $Subject
$mailMessage.Body = $Body
$mailMessage.IsBodyHtml = $true

# --- Add Attachment ---
if (Test-Path $AttachmentPath) {
    $attachment = New-Object System.Net.Mail.Attachment($AttachmentPath)
    $mailMessage.Attachments.Add($attachment)
} else {
    Write-Warning "Attachment not found at $AttachmentPath"
}

# --- Create SMTP Client ---
$smtpClient = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
$smtpClient.EnableSsl = $true # Corresponds to UseSsl/StartTls for port 587 typically
$smtpClient.Credentials = $Credential # Assign the PSCredential object

# --- Send Email ---
try {
    Write-Host "Attempting to send email via $SMTPServer using .NET SmtpClient..."
    $smtpClient.Send($mailMessage)
    Write-Host "Email sent successfully."
}
catch {
    Write-Error "Failed to send email using .NET SmtpClient: $($_.Exception.ToString())"
}
finally {
    # Dispose of objects to release resources
    if ($attachment) { $attachment.Dispose() }
    $mailMessage.Dispose()
    $smtpClient.Dispose()
}