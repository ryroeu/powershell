<#
.SYNOPSIS
    Manages active directory locked accounts.
#>

$properties = @(
    'TimeCreated',
    @{n='Account Name';e={$_.Properties[0].Value}},
    @{n='Caller Computer Name';e={$_.Properties[1].Value}}
)
Get-WinEvent -FilterHashTable @{LogName='Security'; ID=4740} | Select-Object $properties