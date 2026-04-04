<#
.SYNOPSIS
    Manages filename change.
#>

# Replace Characters in Filename inside working Directory
Get-ChildItem | Rename-Item –NewName {$_.Name –Replace " ","_"}