<#
.SYNOPSIS
    Sends an SMTP alert for Windows fixed volumes below configured free-space thresholds.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$SmtpServer,

    [ValidateRange(1, 65535)]
    [int]$SmtpPort = 587,

    [Parameter(Mandatory)]
    [mailaddress]$From,

    [Parameter(Mandatory)]
    [mailaddress[]]$To,

    [pscredential]$Credential,

    [switch]$UseSsl,

    [ValidateRange(0, [double]::MaxValue)]
    [double]$SystemDriveThresholdGB = 10,

    [ValidateRange(0, [double]::MaxValue)]
    [double]$OtherDriveThresholdGB = 60
)

$computerName = $env:COMPUTERNAME
$systemDrive = $env:SystemDrive
$volumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3'

foreach ($volume in $volumes) {
    $threshold = if ($volume.DeviceID -eq $systemDrive) { $SystemDriveThresholdGB } else { $OtherDriveThresholdGB }
    $freeGB = [math]::Round($volume.FreeSpace / 1GB, 2)
    if ($freeGB -ge $threshold) {
        continue
    }

    $subject = "Low disk space on $computerName $($volume.DeviceID)"
    $body = 'Drive {0} on {1} has {2:N2} GB free; threshold is {3:N2} GB.' -f $volume.DeviceID, $computerName, $freeGB, $threshold
    if (-not $PSCmdlet.ShouldProcess(($To -join ', '), "Send alert '$subject'")) {
        continue
    }

    $message = [Net.Mail.MailMessage]::new()
    $client = [Net.Mail.SmtpClient]::new($SmtpServer, $SmtpPort)
    try {
        $message.From = $From
        foreach ($address in $To) { $message.To.Add($address) }
        $message.Subject = $subject
        $message.Body = $body
        $client.EnableSsl = $UseSsl
        if ($Credential) { $client.Credentials = $Credential.GetNetworkCredential() }
        $client.Send($message)
    }
    finally {
        $message.Dispose()
        $client.Dispose()
    }
}
