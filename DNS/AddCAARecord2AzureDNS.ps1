<#
.SYNOPSIS
    Creates or replaces a CAA record set in Azure DNS.
#>

#Requires -Modules Az.Dns

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$ZoneName,

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [string]$Name = '@',

    [Parameter(Mandatory)]
    [string[]]$CertificateAuthority,

    [mailaddress]$IncidentReportAddress,

    [ValidateRange(1, [int]::MaxValue)]
    [int]$Ttl = 3600
)

$records = @($CertificateAuthority | ForEach-Object { New-AzDnsRecordConfig -CaaFlags 0 -CaaTag issue -CaaValue $_ })
if ($IncidentReportAddress) {
    $records += New-AzDnsRecordConfig -CaaFlags 0 -CaaTag iodef -CaaValue "mailto:$($IncidentReportAddress.Address)"
}
if ($PSCmdlet.ShouldProcess("$Name.$ZoneName", 'Create or replace Azure DNS CAA record set')) {
    New-AzDnsRecordSet -Name $Name -RecordType CAA -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -Ttl $Ttl -DnsRecords $records -Overwrite
}
