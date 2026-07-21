<#
.SYNOPSIS
  Empty a SharePoint or OneDrive recycle bin, or permanently delete Entra ID recycled objects.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SharePointSiteUrl,
    [string]$TenantAdminUrl,
    [switch]$TenantLevel,
    [switch]$All,
    [switch]$PurgeDeletedUsers,
    [switch]$ForceDeviceCode,
    [string]$PnPClientId
)

$ErrorActionPreference = 'Stop'

function Install-ModuleIfMissing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$MinVersion = '0.0.0'
    )

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Install-Module -Name $Name -MinimumVersion $MinVersion -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module -Name $Name -MinimumVersion $MinVersion -ErrorAction Stop
}

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

    throw 'PnP.PowerShell interactive login requires a ClientId. Pass -PnPClientId or set ENTRAID_APP_ID/ENTRAID_CLIENT_ID.'
}

function Connect-PnPSite {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$ClientId,

        [switch]$DeviceLogin
    )

    $connectParams = @{
        Url              = $Url
        ClientId         = $ClientId
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

function Select-RecycleBinItem {
    param(
        [Parameter(Mandatory)]
        [object[]]$Items
    )

    if (Get-Command -Name Out-GridView -ErrorAction SilentlyContinue) {
        $selectedRows = @(
            $Items |
                Select-Object ItemType, LeafName, DirName, DeletedByName, DeletedDate |
                Out-GridView -PassThru -Title 'Select recycle bin items to clear'
        )

        if (-not $selectedRows) {
            return @()
        }

        return @(
            foreach ($row in $selectedRows) {
                $Items | Where-Object {
                    $_.ItemType -eq $row.ItemType -and
                    $_.LeafName -eq $row.LeafName -and
                    $_.DirName -eq $row.DirName -and
                    $_.DeletedDate -eq $row.DeletedDate
                } | Select-Object -First 1
            }
        )
    }

    $indexedItems = for ($index = 0; $index -lt $Items.Count; $index++) {
        [pscustomobject]@{
            Index       = $index
            ItemType    = $Items[$index].ItemType
            Name        = $Items[$index].LeafName
            Directory   = $Items[$index].DirName
            DeletedBy   = $Items[$index].DeletedByName
            DeletedDate = $Items[$index].DeletedDate
        }
    }

    $indexedItems | Select-Object -First 25 | Format-Table -AutoSize | Out-Host
    Write-Host 'Out-GridView is unavailable, so the first 25 items are shown above.'

    $selection = Read-Host 'Enter comma-separated indexes to clear, or press Enter to cancel'
    if ([string]::IsNullOrWhiteSpace($selection)) {
        return @()
    }

    $indexes = $selection -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\d+$' } |
        ForEach-Object { [int]$_ } |
        Sort-Object -Unique

    return @(
        foreach ($index in $indexes) {
            if ($index -lt $Items.Count) {
                $Items[$index]
            }
        }
    )
}

if ($PurgeDeletedUsers) {
    Install-ModuleIfMissing -Name Microsoft.Graph -MinVersion '2.12.0'

    $scopes = @('Directory.AccessAsUser.All', 'User.ReadWrite.All')
    if ($ForceDeviceCode) {
        Connect-MgGraph -Scopes $scopes -UseDeviceCode -NoWelcome | Out-Null
    }
    else {
        Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null
    }

    try {
        $deletedItems = @(Get-MgDirectoryDeletedItemAsUser -All -ErrorAction SilentlyContinue)
        $deletedUsers = @(
            $deletedItems | Where-Object {
                $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user'
            }
        )

        if (-not $deletedUsers) {
            $deletedUsers = $deletedItems
        }

        if (-not $deletedUsers) {
            Write-Output 'No deleted users were found.'
            return
        }

        foreach ($user in $deletedUsers) {
            if ($PSCmdlet.ShouldProcess($user.Id, 'Hard delete recycled directory object')) {
                Remove-MgDirectoryDeletedItem -DirectoryObjectId $user.Id -Confirm:$false
            }
        }

        Write-Output 'Deleted user recycle bin purged.'
        return
    }
    finally {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}

Install-ModuleIfMissing -Name PnP.PowerShell -MinVersion '2.5.0'
$resolvedClientId = Get-PnPClientId -ExplicitClientId $PnPClientId

if ($TenantLevel) {
    if (-not $TenantAdminUrl) {
        throw '-TenantAdminUrl is required when using -TenantLevel.'
    }

    $connection = Connect-PnPSite -Url $TenantAdminUrl -ClientId $resolvedClientId -DeviceLogin:$ForceDeviceCode
    $items = @(Get-PnPTenantRecycleBinItem -RowLimit 5000 -Connection $connection)

    if (-not $items) {
        Write-Output 'Tenant recycle bin is empty.'
        return
    }

    if ($PSCmdlet.ShouldProcess('Tenant recycle bin', ('Clear {0} item(s)' -f $items.Count))) {
        $items | Clear-PnPTenantRecycleBinItem -Force
        Write-Output 'Tenant recycle bin cleared.'
    }

    return
}

if (-not $SharePointSiteUrl) {
    throw 'Provide -SharePointSiteUrl or use -TenantLevel.'
}

$siteConnection = Connect-PnPSite -Url $SharePointSiteUrl -ClientId $resolvedClientId -DeviceLogin:$ForceDeviceCode

if ($All) {
    if ($PSCmdlet.ShouldProcess($SharePointSiteUrl, 'Clear first-stage and second-stage recycle bins')) {
        Get-PnPRecycleBinItem -Connection $siteConnection -RowLimit 5000 -SecondStage:$false | Clear-PnPRecycleBinItem -Force
        Get-PnPRecycleBinItem -Connection $siteConnection -RowLimit 5000 -SecondStage:$true | Clear-PnPRecycleBinItem -Force
        Write-Output 'Site recycle bin cleared.'
    }

    return
}

$recycleBinItems = @(Get-PnPRecycleBinItem -Connection $siteConnection -RowLimit 5000)
if (-not $recycleBinItems) {
    Write-Output 'Site recycle bin is empty.'
    return
}

$selectedItems = @(Select-RecycleBinItem -Items $recycleBinItems)
if (-not $selectedItems) {
    Write-Output 'No recycle bin items were selected.'
    return
}

if ($PSCmdlet.ShouldProcess($SharePointSiteUrl, ('Clear {0} selected recycle bin item(s)' -f $selectedItems.Count))) {
    $selectedItems | Clear-PnPRecycleBinItem -Force
    Write-Output 'Selected recycle bin items cleared.'
}
