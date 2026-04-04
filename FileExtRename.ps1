<#
.SYNOPSIS
    Renames file ext.
#>

Get-ChildItem *.csv | Rename-Item -NewName { [io.path]::ChangeExtension($_.name, "xlsx") }