<#
.SYNOPSIS
    Adds caar ecord 2 azure DNS.
#>

$zonename = "example1.com"
$resourcegroup = "resourcegroup"
$certificateauthority = "digicert.com" # Possible values are: `letsencrypt.org`, `digicert.com`
$incidentreport = "you@example1.com" # This will be your personal email id where you want to receive alerts about the Cert incident reports.

$addcaarecord = @()
$addcaarecord += New-AzDnsRecordConfig -Caaflags 0 -CaaTag "issue" -CaaValue $certificateauthority
$addcaarecord += New-AzDnsRecordConfig -Caaflags 0 -CaaTag "iodef" -CaaValue "mailto:$incidentreport"
New-AzDnsRecordSet -Name "@" -RecordType CAA -ZoneName $zoneName -ResourceGroupName $resourcegroup -Ttl 3600 -DnsRecords ($addcaarecord)