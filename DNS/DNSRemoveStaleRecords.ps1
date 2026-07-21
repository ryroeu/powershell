<#
.SYNOPSIS
    Removes timestamped DNS records older than a specified age.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$ZoneName,

    [string]$ComputerName = $env:COMPUTERNAME,

    [ValidateSet('A', 'AAAA', 'CNAME', 'PTR')]
    [string]$RecordType = 'A',

    [ValidateRange(1, 3650)]
    [int]$OlderThanDays = 14
)

$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$records = Get-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName -RRType $RecordType |
    Where-Object { $_.Timestamp -and $_.Timestamp -le $cutoff }

foreach ($record in $records) {
    $target = '{0}.{1} ({2})' -f $record.HostName, $ZoneName, $record.RecordType
    if ($PSCmdlet.ShouldProcess($target, "Remove stale DNS record from $ComputerName")) {
        Remove-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName -InputObject $record -Force
    }
}
