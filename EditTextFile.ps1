<#
.SYNOPSIS
    Edits text file.
#>

$line = Get-Content c:\filename.txt | Select-String "beginning text of line to be edited" | Select-Object -ExpandProperty Line
$content = Get-Content c:\filename.txt
$content | ForEach-Object {$_ -replace $line,"new text for line"} | Set-Content c:\filename.txt