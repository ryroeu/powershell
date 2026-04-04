#Requires -Modules Microsoft.Online.SharePoint.PowerShell

<#
.SYNOPSIS
    Connects to SharePoint Online.
#>

[CmdletBinding(DefaultParameterSetName = 'Browser')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantName,

    [Parameter(Mandatory, ParameterSetName = 'Credential')]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(ParameterSetName = 'Browser')]
    [switch]$UseSystemBrowser,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [ValidateNotNullOrEmpty()]
    [string]$ClientId,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter(ParameterSetName = 'Certificate')]
    [string]$CertificateThumbprint,

    [Parameter(ParameterSetName = 'Certificate')]
    [string]$CertificatePath,

    [Parameter(ParameterSetName = 'Certificate')]
    [securestring]$CertificatePassword,

    [ValidateNotNullOrEmpty()]
    [string]$AuthenticationUrl = 'https://login.microsoftonline.com/organizations'
)

$adminUrl = 'https://{0}-admin.sharepoint.com' -f $TenantName
$connectParams = @{
    Url = $adminUrl
}

switch ($PSCmdlet.ParameterSetName) {
    'Credential' {
        $connectParams.Credential = $Credential
        $connectParams.ModernAuth = $true
        $connectParams.AuthenticationUrl = $AuthenticationUrl
    }
    'Browser' {
        $connectParams.UseSystemBrowser = $true
    }
    'Certificate' {
        $connectParams.ClientId = $ClientId
        $connectParams.TenantId = $TenantId

        if ($CertificateThumbprint) {
            $connectParams.CertificateThumbprint = $CertificateThumbprint
        }
        elseif ($CertificatePath) {
            $connectParams.CertificatePath = $CertificatePath
            if ($CertificatePassword) {
                $connectParams.CertificatePassword = $CertificatePassword
            }
        }
        else {
            throw 'Provide -CertificateThumbprint or -CertificatePath when using the Certificate parameter set.'
        }
    }
}

Connect-SPOService @connectParams
Write-Output ('Connected to {0}' -f $adminUrl)
