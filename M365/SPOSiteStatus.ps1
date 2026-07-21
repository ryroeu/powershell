#Requires -Modules Microsoft.Online.SharePoint.PowerShell

<#
.SYNOPSIS
    Lists or changes SharePoint Online site lock states.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Browser')]
param(
    [Parameter(Mandatory)]
    [string]$TenantName,

    [ValidateSet('ListNoAccess', 'ListReadOnly', 'SetNoAccess', 'SetReadOnly', 'Unlock')]
    [string]$Action,

    [string]$SiteUrl,

    [Parameter(Mandatory, ParameterSetName = 'Credential')]
    [pscredential]$Credential,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$ClientId,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$TenantId,

    [Parameter(ParameterSetName = 'Certificate')]
    [string]$CertificateThumbprint,

    [Parameter(ParameterSetName = 'Certificate')]
    [string]$CertificatePath,

    [Parameter(ParameterSetName = 'Certificate')]
    [securestring]$CertificatePassword,

    [string]$AuthenticationUrl = 'https://login.microsoftonline.com/organizations'
)

$adminUrl = 'https://{0}-admin.sharepoint.com' -f $TenantName
$connectParameters = @{ Url = $adminUrl }
switch ($PSCmdlet.ParameterSetName) {
    'Credential' {
        $connectParameters.Credential = $Credential
        $connectParameters.ModernAuth = $true
        $connectParameters.AuthenticationUrl = $AuthenticationUrl
    }
    'Certificate' {
        $connectParameters.ClientId = $ClientId
        $connectParameters.TenantId = $TenantId
        if ($CertificateThumbprint) {
            $connectParameters.CertificateThumbprint = $CertificateThumbprint
        }
        elseif ($CertificatePath) {
            $connectParameters.CertificatePath = $CertificatePath
            if ($CertificatePassword) { $connectParameters.CertificatePassword = $CertificatePassword }
        }
        else {
            throw 'Provide -CertificateThumbprint or -CertificatePath for certificate authentication.'
        }
    }
    default {
        $connectParameters.UseSystemBrowser = $true
    }
}
Connect-SPOService @connectParameters

if (-not $Action) {
    $menu = [ordered]@{ '1'='ListNoAccess'; '2'='ListReadOnly'; '3'='SetNoAccess'; '4'='SetReadOnly'; '5'='Unlock' }
    $menu.GetEnumerator() | ForEach-Object { '{0}. {1}' -f $_.Key, $_.Value }
    $selection = Read-Host 'Choose an action [1-5]'
    if (-not $menu.Contains($selection)) { throw 'Invalid menu selection.' }
    $Action = $menu[$selection]
}

if ($Action -like 'List*') {
    $lockState = if ($Action -eq 'ListNoAccess') { 'NoAccess' } else { 'ReadOnly' }
    Get-SPOSite -Limit All |
        Where-Object LockState -eq $lockState |
        Select-Object Url, Title, Owner, LockState
    return
}

if (-not $SiteUrl) { throw '-SiteUrl is required for state-changing actions.' }
$lockState = switch ($Action) {
    'SetNoAccess' { 'NoAccess' }
    'SetReadOnly' { 'ReadOnly' }
    'Unlock' { 'Unlock' }
}
if ($PSCmdlet.ShouldProcess($SiteUrl, "Set SharePoint Online lock state to $lockState")) {
    Set-SPOSite -Identity $SiteUrl -LockState $lockState
    Get-SPOSite -Identity $SiteUrl | Select-Object Url, Title, Owner, LockState
}
