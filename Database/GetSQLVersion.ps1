<#
.SYNOPSIS
    Retrieves installed SQL Server instance editions and patch levels from the registry.
#>

[CmdletBinding()]
param()

$instanceRoot = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
if (-not (Test-Path -LiteralPath $instanceRoot)) {
    Write-Verbose 'No 64-bit SQL Server instances were found.'
    return
}

$instanceNames = Get-ItemProperty -LiteralPath $instanceRoot
foreach ($property in $instanceNames.PSObject.Properties.Where({ $_.Name -notmatch '^PS' })) {
    $setupPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($property.Value)\Setup"
    $setup = Get-ItemProperty -LiteralPath $setupPath -ErrorAction Stop
    [pscustomobject]@{
        InstanceName = $property.Name
        InstanceId   = $property.Value
        Edition      = $setup.Edition
        Version      = $setup.Version
        PatchLevel   = $setup.PatchLevel
    }
}
