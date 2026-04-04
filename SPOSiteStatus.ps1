#Requires -Modules Microsoft.Online.SharePoint.PowerShell

[CmdletBinding(DefaultParameterSetName = 'Browser')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantName,

    [ValidateSet('ListNoAccess', 'ListReadOnly', 'SetNoAccess', 'SetReadOnly', 'Unlock')]
    [string]$Action,

    [string]$SiteUrl,

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

function Connect-SharePointAdmin {
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
}

if (-not $Action) {
    $menu = [ordered]@{
        '1' = 'ListNoAccess'
        '2' = 'ListReadOnly'
        '3' = 'SetNoAccess'
        '4' = 'SetReadOnly'
        '5' = 'Unlock'
    }

    $menu.GetEnumerator() | ForEach-Object {
        Write-Output ('{0}. {1}' -f $_.Key, $_.Value)
    }

    $selection = Read-Host 'Choose an action [1-5]'
    if (-not $menu.Contains($selection)) {
        throw 'Invalid menu selection.'
    }

    $Action = $menu[$selection]
}

if ($Action -in @('SetNoAccess', 'SetReadOnly', 'Unlock') -and -not $SiteUrl) {
    $SiteUrl = Read-Host 'Enter the site collection URL to update'
}

Connect-SharePointAdmin

switch ($Action) {
    'ListNoAccess' {
        Get-SPOSite -Limit All |
            Where-Object LockState -eq 'NoAccess' |
            Select-Object Url, Title, Owner, LockState
    }
    'ListReadOnly' {
        Get-SPOSite -Limit All |
            Where-Object LockState -eq 'ReadOnly' |
            Select-Object Url, Title, Owner, LockState
    }
    'SetNoAccess' {
        Set-SPOSite -Identity $SiteUrl -LockState NoAccess
        Get-SPOSite -Identity $SiteUrl | Select-Object Url, Title, Owner, LockState
    }
    'SetReadOnly' {
        Set-SPOSite -Identity $SiteUrl -LockState ReadOnly
        Get-SPOSite -Identity $SiteUrl | Select-Object Url, Title, Owner, LockState
    }
    'Unlock' {
        Set-SPOSite -Identity $SiteUrl -LockState Unlock
        Get-SPOSite -Identity $SiteUrl | Select-Object Url, Title, Owner, LockState
    }
}
