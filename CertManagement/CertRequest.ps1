<#
.SYNOPSIS
    Requests a certificate from an Active Directory Certificate Services enrollment endpoint.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Template,

    [Parameter(Mandatory)]
    [string[]]$DnsName,

    [uri]$Url,

    [pscredential]$Credential,

    [string]$CertStoreLocation = 'Cert:\LocalMachine\My'
)

$parameters = @{ Template = $Template; DnsName = $DnsName; CertStoreLocation = $CertStoreLocation }
if ($Url) { $parameters.Url = $Url }
if ($Credential) { $parameters.Credential = $Credential }
if ($PSCmdlet.ShouldProcess(($DnsName -join ', '), "Request certificate using template '$Template'")) {
    Get-Certificate @parameters
}
