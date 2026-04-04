[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$TrustPSGallery,
    [switch]$IncludeLegacySharePointModule,
    [switch]$UpdateExisting
)

$modules = @(
    '7Zip4Powershell',
    'ActiveDirectoryDsc',
    'AWSPowerShell',
    'AWS.Tools.Common',
    'Az',
    'CertificateDsc',
    'ChocolateyGet',
    'ComputerManagementDsc',
    'DellBIOSProvider',
    'ExchangeOnlineManagement',
    'IISAdministration',
    'Microsoft.Graph',
    'NetworkingDsc',
    'NuGet',
    'PackageManagement',
    'PnP.PowerShell',
    'PowerShellGet',
    'PSScriptAnalyzer',
    'PSWindowsUpdate',
    'SqlServerDsc',
    'VMware.PowerCLI'
)

$isWindowsPlatform = ($IsWindows -eq $true) -or ($env:OS -eq 'Windows_NT')

if ($IncludeLegacySharePointModule) {
    if ($isWindowsPlatform) {
        $modules += 'Microsoft.Online.SharePoint.PowerShell'
    }
    else {
        Write-Warning 'Skipping Microsoft.Online.SharePoint.PowerShell because it is only supported on Windows.'
    }
}

$modules = $modules | Sort-Object -Unique

if ($TrustPSGallery -and $PSCmdlet.ShouldProcess('PSGallery', 'Set installation policy to Trusted')) {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

foreach ($moduleName in $modules) {
    $installedModule = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
    if ($installedModule -and -not $UpdateExisting) {
        Write-Verbose ('Skipping {0}; it is already installed.' -f $moduleName)
        continue
    }

    if ($PSCmdlet.ShouldProcess($moduleName, 'Install or update module')) {
        Install-Module -Name $moduleName -Scope CurrentUser -Force -Confirm:$false -AllowClobber
    }
}

Get-InstalledModule | Where-Object Name -in $modules | Sort-Object Name, Version
