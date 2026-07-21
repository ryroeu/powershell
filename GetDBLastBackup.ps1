<#
.SYNOPSIS
    Reports the last full, differential, and log backup recorded for SQL Server databases.
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
        $server = [Microsoft.SqlServer.Management.Smo.Server]::new($instance)
        try {
            $null = $server.VersionString
            foreach ($database in $server.Databases) {
                if ($ExcludeSystemDatabase -and $database.IsSystemObject) { continue }
                [pscustomobject]@{
                    Server                 = $server.Name
                    Database               = $database.Name
                    LastFullBackup         = if ($database.LastBackupDate -eq [datetime]::MinValue) { $null } else { $database.LastBackupDate }
                    LastDifferentialBackup = if ($database.LastDifferentialBackupDate -eq [datetime]::MinValue) { $null } else { $database.LastDifferentialBackupDate }
                    LastLogBackup          = if ($database.LastLogBackupDate -eq [datetime]::MinValue) { $null } else { $database.LastLogBackupDate }
                }
            }
        }
        finally {
            if ($server.ConnectionContext.IsOpen) { $server.ConnectionContext.Disconnect() }
        }
    }
}
