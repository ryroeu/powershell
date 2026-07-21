<#
.SYNOPSIS
    Repairs the current user's legacy shell-folder registry values.
.DESCRIPTION
    Sets both Shell Folders and User Shell Folders from a caller-supplied root path. Group Policy
    folder redirection should be repaired through Group Policy instead of with this script.
.EXAMPLE
    ./FolderRedirectFix.ps1 -RedirectRoot '\\FileServer\Users\Ryan'
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$RedirectRoot
)

if (-not $IsWindows) {
    throw 'This script requires Windows.'
}

$redirectRoot = $RedirectRoot.TrimEnd('\')
$folders = [ordered]@{
    'Administrative Tools' = 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Administrative Tools'
    AppData                = 'AppData\Roaming'
    Desktop                = 'Desktop'
    Favorites              = 'Favorites'
    'My Pictures'          = 'Pictures'
    NetHood                = 'AppData\Roaming\Microsoft\Windows\Network Shortcuts'
    Personal               = 'Documents'
    PrintHood              = 'AppData\Roaming\Microsoft\Windows\Printer Shortcuts'
    Programs               = 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs'
    Recent                 = 'AppData\Roaming\Microsoft\Windows\Recent'
    SendTo                 = 'AppData\Roaming\Microsoft\Windows\SendTo'
    'Start Menu'           = 'AppData\Roaming\Microsoft\Windows\Start Menu'
    Startup                = 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'
    Templates              = 'AppData\Roaming\Microsoft\Windows\Templates'
}

$registryPaths = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
)

foreach ($registryPath in $registryPaths) {
    if (-not (Test-Path -LiteralPath $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }

    foreach ($entry in $folders.GetEnumerator()) {
        $value = Join-Path -Path $redirectRoot -ChildPath $entry.Value
        if ($PSCmdlet.ShouldProcess("$registryPath :: $($entry.Key)", "Set value to '$value'")) {
            New-ItemProperty -Path $registryPath -Name $entry.Key -Value $value -PropertyType String -Force | Out-Null
        }
    }
}

Write-Warning 'Sign out and back in before evaluating the repaired shell-folder paths.'
