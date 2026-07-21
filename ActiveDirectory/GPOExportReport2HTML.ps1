<#
.SYNOPSIS
    Exports one or all Group Policy Objects to an HTML report.
#>

#Requires -Modules GroupPolicy

[CmdletBinding(DefaultParameterSetName = 'All')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Name')]
    [string]$Name,

    [Parameter(ParameterSetName = 'All')]
    [switch]$All,

    [string]$Path = (Join-Path $PWD 'GPOReport.html'),

    [string]$Domain,

    [string]$Server
)

$parameters = @{ ReportType = 'Html'; Path = $Path }
if ($PSCmdlet.ParameterSetName -eq 'Name') {
    $parameters.Name = $Name
}
elseif ($All -or $PSCmdlet.ParameterSetName -eq 'All') {
    $parameters.All = $true
}
if ($Domain) { $parameters.Domain = $Domain }
if ($Server) { $parameters.Server = $Server }
Get-GPOReport @parameters
Get-Item -LiteralPath $Path
