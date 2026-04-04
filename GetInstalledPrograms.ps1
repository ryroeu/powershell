<#
.SYNOPSIS
    Retrieves installed programs.
#>

# Get Installed Software
# Define the registry paths
$paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' # For 32-bit apps on 64-bit OS
)

# Query the registry, filter out entries without display names, select desired properties, and format
Get-ItemProperty $paths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -ne $null -and $_.DisplayName -ne '' } |
    Select-Object @{Name='Vendor'; Expression={$_.Publisher}},
                  @{Name='Name'; Expression={$_.DisplayName}},
                  @{Name='Version'; Expression={$_.DisplayVersion}},
                  InstallDate |
    Sort-Object Vendor, Name |
    Format-Table -AutoSize