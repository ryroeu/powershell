<#
.SYNOPSIS
    Exports Group Policy report 2 html.
#>

Get-GPOReport -All -ReportType HTML -Path ".\GPOReportAll.html" -Force
# Get-GPOReport -Name "TestGPO1" -ReportType HTML -Path ".\GPOReport.html" -Force