<#
.SYNOPSIS
Shows how to export and import credentials by using `Export-Clixml` and `Import-Clixml`.
#>
Get-Credential -Credential $env:USERNAME
# Export
$Credxmlpath = Join-Path (Split-Path $Profile) NameOfScript.ps1.credential
$Credential | Export-CliXml $Credxmlpath
# Import
$Credxmlpath = Join-Path (Split-Path $Profile) NameOfScript.ps1.credential
$Credential = Import-CliXml $Credxmlpath
