<#
.SYNOPSIS
    Manages kms multiple operating systems activation.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

#### Installs the appropriate KMS client key for the detected OS ####
$OSversion = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
switch -Regex ($OSversion) {
    'Windows 11 Pro' { $key = 'W269N-WFGWX-YVC9B-4J6C9-T83GX'; break }
    'Windows 11 Enterprise' { $key = 'NPPR9-FWDCX-D2C8J-H872K-2YT43'; break }
    'Windows Server 2025 Standard' { $key = 'TVRH6-WHNXV-R9WG3-9XRFY-MY832'; break }
    'Windows Server 2025 Datacenter' { $key = 'D764K-2NDRG-47T6Q-P8T8W-YP6DF'; break }
}
if (-not $key) {
    throw "No KMS client key is configured for detected operating system '$OSversion'."
}
$KMSservice = Get-CimInstance -Query "SELECT * FROM SoftwareLicensingService"
Write-Debug 'Activating Windows.'
if ($PSCmdlet.ShouldProcess($OSversion, 'Install KMS client key and refresh license status')) {
    $null = Invoke-CimMethod -InputObject $KMSservice -MethodName 'InstallProductKey' -Arguments @{ ProductKey = $key }
    $null = Invoke-CimMethod -InputObject $KMSservice -MethodName 'RefreshLicenseStatus'
}
