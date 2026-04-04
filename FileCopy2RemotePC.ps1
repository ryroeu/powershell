<#
.SYNOPSIS
    Manages file copy 2 remote pc.
#>

Get-Credential domain\usermname
$PC = Read-Host ".\ListOfPCs.csv"
$FileLocation = Read-Host ".\filename.ext"
$FileDestination = Read-Host "C:\temp\"
Get-Content $PC | ForEach-Object {Copy-Item $FileLocation -Destination \\$_\c$\$FileDestination}