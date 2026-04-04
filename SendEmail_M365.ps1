#Requires -Modules Microsoft.Graph.Mail

<#
.SYNOPSIS
    Sends email Microsoft 365.
#>

# --- Configuration (Replace with your actual values) ---
$TenantId = "YOUR_TENANT_ID"
$AppId = "YOUR_APP_REGISTRATION_CLIENT_ID"
$AppSecret = "YOUR_APP_REGISTRATION_CLIENT_SECRET" # Or use Certificate Thumbprint
$SenderUserPrincipalName = "user.who.can.send@yourdomain.com" # User whose mailbox will send

$ToRecipient = @{
    emailAddress = @{
        address = "recipient@domain.com"
    }
}
# Multiple recipients: $ToRecipientArray = @( @{emailAddress=@{address="r1@d.com"}}, @{emailAddress=@{address="r2@d.com"}} )

$CcRecipient = @{
    emailAddress = @{
        address = "cc-user@domain.com"
    }
}
# Multiple CCs: $CcRecipientArray = @( @{emailAddress=@{address="cc1@d.com"}} )


$Subject = "File Request (Sent via Graph)"
$BodyContent = @"
<h2>Here is the file you requested</h2>
<br><br>
Name of file: File.jpg
"@
$Body = @{
    contentType = "HTML" # Or "Text"
    content = $BodyContent
}

# --- Optional: Attachment ---
$AttachmentPath = "C:\Temp\File.jpg"
$AttachmentBytes = [System.IO.File]::ReadAllBytes($AttachmentPath)
$AttachmentBase64 = [System.Convert]::ToBase64String($AttachmentBytes)
$AttachmentFileName = [System.IO.Path]::GetFileName($AttachmentPath)

$Attachments = @(
    @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name = $AttachmentFileName
        contentType = "image/jpeg" # Adjust MIME type as needed (e.g., application/pdf)
        contentBytes = $AttachmentBase64
    }
)

# --- Connect to Microsoft Graph (using Application permissions) ---
# NOTE: Secret should be handled securely (e.g., Azure Key Vault, Windows Credential Manager)
$SecureAppSecret = ConvertTo-SecureString $AppSecret -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($AppId, $SecureAppSecret)

try {
    Write-Host "Connecting to Microsoft Graph..."
    # Ensure required scope is requested if not already consented in App Registration
    Connect-MgGraph -TenantId $TenantId -AppId $AppId -Credential $Credential
    Write-Host "Connected successfully."

    # --- Send Email ---
    Write-Host "Attempting to send email from $SenderUserPrincipalName..."
    Send-MgUserMail -UserId $SenderUserPrincipalName `
                    -Message @{
                        subject = $Subject
                        body = $Body
                        toRecipients = @($ToRecipient) # Ensure it's an array
                        ccRecipients = @($CcRecipient) # Ensure it's an array
                        attachments = $Attachments # Add this line for attachments
                    } `
                    -SaveToSentItems $true # Or $false

    Write-Host "Email command sent successfully via Microsoft Graph."

}
catch {
    Write-Error "Failed to send email via Graph: $($_.Exception.Message)"
    Write-Error "Status Code: $($_.Exception.Response.StatusCode)"
    Write-Error "Response: $($_.Exception.Response.Content)"
}
finally {
    # Disconnect if needed, especially in longer scripts
    Disconnect-MgGraph
}