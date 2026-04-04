#Requires -Modules PnP.PowerShell

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantAdminUrl,

    [string]$ClientId,

    [switch]$UseDeviceLogin,

    [switch]$IncludeOneDriveSites,

    [switch]$IncludeSubwebs,

    [switch]$Detailed,

    [string]$Filter,

    [string]$ExportPath
)

function Get-PnPClientId {
    param(
        [string]$ExplicitClientId
    )

    foreach ($candidate in @(
        $ExplicitClientId,
        $env:ENTRAID_APP_ID,
        $env:ENTRAID_CLIENT_ID,
        $env:AZURE_CLIENT_ID
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            return $candidate
        }
    }

    throw 'PnP.PowerShell interactive login now requires a ClientId. Pass -ClientId or set ENTRAID_APP_ID/ENTRAID_CLIENT_ID.'
}

function New-PnPInteractiveConnection {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$ResolvedClientId,

        [switch]$DeviceLogin
    )

    $connectParams = @{
        Url              = $Url
        ClientId         = $ResolvedClientId
        ReturnConnection = $true
    }

    if ($DeviceLogin) {
        $connectParams.DeviceLogin = $true
    }
    else {
        $connectParams.Interactive = $true
    }

    Connect-PnPOnline @connectParams
}

$resolvedClientId = Get-PnPClientId -ExplicitClientId $ClientId
$adminConnection = New-PnPInteractiveConnection -Url $TenantAdminUrl -ResolvedClientId $resolvedClientId -DeviceLogin:$UseDeviceLogin

$tenantSiteParams = @{
    Connection = $adminConnection
}

if ($Detailed) {
    $tenantSiteParams.Detailed = $true
}

if ($IncludeOneDriveSites) {
    $tenantSiteParams.IncludeOneDriveSites = $true
}

if ($Filter) {
    $tenantSiteParams.Filter = $Filter
}

$sites = @(Get-PnPTenantSite @tenantSiteParams)
$rows = [System.Collections.Generic.List[object]]::new()

foreach ($site in $sites) {
    $rows.Add([pscustomobject]@{
            EntryType         = 'SiteCollection'
            SiteCollectionUrl = $site.Url
            WebUrl            = $site.Url
            Title             = $site.Title
            Template          = $site.Template
            LockState         = $site.LockState
        })

    if (-not $IncludeSubwebs) {
        continue
    }

    try {
        $siteConnection = New-PnPInteractiveConnection -Url $site.Url -ResolvedClientId $resolvedClientId -DeviceLogin:$UseDeviceLogin
        $subwebs = @(Get-PnPSubWeb -Connection $siteConnection -Recurse)
        foreach ($web in $subwebs) {
            if ($web.Url -eq $site.Url) {
                continue
            }

            $rows.Add([pscustomobject]@{
                    EntryType         = 'Subweb'
                    SiteCollectionUrl = $site.Url
                    WebUrl            = $web.Url
                    Title             = $web.Title
                    Template          = $web.WebTemplate
                    LockState         = $site.LockState
                })
        }
    }
    catch {
        Write-Warning ('Failed to enumerate subwebs for {0}: {1}' -f $site.Url, $_.Exception.Message)
    }
}

if ($ExportPath) {
    $exportDirectory = Split-Path -Path $ExportPath -Parent
    if ($exportDirectory -and -not (Test-Path -LiteralPath $exportDirectory)) {
        New-Item -ItemType Directory -Path $exportDirectory -Force | Out-Null
    }

    $rows | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
}

$rows
