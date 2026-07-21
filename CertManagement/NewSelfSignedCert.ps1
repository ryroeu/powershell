<#
.SYNOPSIS
    Creates a self-signed certificate in a Windows certificate store.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string[]]$DnsName,

    [string]$FriendlyName = 'PowerShell Automation',

    [ValidateRange(1, 120)]
    [int]$ValidMonths = 24,

    [string]$CertStoreLocation = 'Cert:\LocalMachine\My'
)

$subject = 'CN={0}' -f $DnsName[0]
if ($PSCmdlet.ShouldProcess($subject, "Create self-signed certificate in '$CertStoreLocation'")) {
    New-SelfSignedCertificate -DnsName $DnsName -Subject $subject -FriendlyName $FriendlyName -NotAfter (Get-Date).AddMonths($ValidMonths) -CertStoreLocation $CertStoreLocation
}
