<#
.SYNOPSIS
    Lists databases on one or more SQL Server instances.
#>

#Requires -Modules SqlServer

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ServerInstance,

    [switch]$ExcludeSystemDatabase
)

process {
    foreach ($instance in $ServerInstance) {
        Get-SqlDatabase -ServerInstance $instance -ErrorAction Stop |
            Where-Object { -not $ExcludeSystemDatabase -or -not $_.IsSystemObject } |
            Select-Object @{ Name = 'ServerInstance'; Expression = { $instance } }, Name, Status, Owner, RecoveryModel, Size, CreateDate
    }
}
