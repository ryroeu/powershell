<#
.SYNOPSIS
    Retrieves command.
#>

# Get commands for AWS PowerShell
Get-Command -Module AWSPowerShell | Select-Object Name, Module, Version, Visibility, Definition | Export-CSV 'C:\Temp\AWSPowerShell.csv' -NoTypeInformation -Force
# Get commands for Azure
Get-Command -Module Azure | Select-Object Name, Module, Version, Visibility, Definition | Export-CSV 'C:\Temp\Azure.csv' -NoTypeInformation -Force
# Get commands for Azure Storage
Get-Command -Module Azure.Storage | Select-Object Name, Module, Version, Visibility, Definition | Export-CSV 'C:\Temp\AzureStorage.csv' -NoTypeInformation -Force
