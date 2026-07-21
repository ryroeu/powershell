<#
.SYNOPSIS
    Removes DNS records that reference a decommissioned domain controller.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$ZoneName,

    [Parameter(Mandatory)]
    [string]$DomainControllerName,

    [ipaddress]$IPAddress,

    [string]$ComputerName = $env:COMPUTERNAME
)

$normalizedName = $DomainControllerName.TrimEnd('.') + '.'
$records = Get-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName
foreach ($record in $records) {
    $recordValues = @($record.RecordData.PSObject.Properties.Value | ForEach-Object { $_.ToString() })
    $matchesName = $recordValues -contains $normalizedName -or $recordValues -contains $DomainControllerName.TrimEnd('.')
    $matchesAddress = $IPAddress -and $recordValues -contains $IPAddress.IPAddressToString
    if (-not ($matchesName -or $matchesAddress)) { continue }

    if ($PSCmdlet.ShouldProcess("$($record.HostName).$ZoneName", 'Remove domain-controller DNS record')) {
        Remove-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName -InputObject $record -Force
    }
}
