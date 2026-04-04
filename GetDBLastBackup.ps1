#Requires -Modules SqlServer

<#
.SYNOPSIS
    Retrieves database last backup.
#>

Function Show-LastServerBackup {
  <#
  .SYNOPSIS
  Retrieves the last backup dates (Full, Differential, Log) for all databases on a specified SQL Server instance.

  .DESCRIPTION
  Connects to the target SQL Server instance using the SqlServer PowerShell module (SMO).
  It iterates through each database and reports the last time a full, differential, or log backup was recorded.
  Requires the 'SqlServer' module to be installed (`Install-Module -Name SqlServer`).

  .PARAMETER SQLServer
  The name of the SQL Server instance to connect to (e.g., "ServerName", "ServerName\InstanceName").

  .PARAMETER ExcludeSystemDatabases
  If specified, system databases (master, model, msdb, tempdb) will be excluded from the results.

  .EXAMPLE
  Show-LastServerBackup -SQLServer "MyDatabaseServer"

  .EXAMPLE
  Show-LastServerBackup -SQLServer "MyDevServer\SQLEXPRESS" -ExcludeSystemDatabases

  .EXAMPLE
  "MyProdServer1", "MyProdServer2" | Show-LastServerBackup | Format-Table -AutoSize

  .OUTPUTS
  PSCustomObject with properties: Server, Database, LastFullBackup, LastDiffBackup, LastLogBackup.
  Outputs 'NEVER' if a backup of that type has not been recorded.
  Outputs the DateTime object otherwise.

  .NOTES
  Date:   2025-04-04
  Requires: PowerShell Core 7+ and the 'SqlServer' module.
  Install Module: Install-Module -Name SqlServer -Scope CurrentUser
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
      [string]$SQLServer,

      [Parameter()]
      [switch]$ExcludeSystemDatabases
  )

  Begin {
      # Check if the SqlServer module is loaded or available
      if (-not (Get-Module -Name SqlServer -ListAvailable)) {
          Write-Error "The 'SqlServer' module is required but not found. Please install it using: Install-Module -Name SqlServer"
          # Use 'throw' to halt processing completely if the module is critical
          throw "Required module 'SqlServer' not found."
      }
      Write-Verbose "SqlServer module found. Proceeding..."
      $minDate = [DateTime]::MinValue
  }

  Process {
      $serverObject = $null # Initialize to null for finally block check
      try {
          Write-Verbose "Attempting connection to SQL Server instance: $SQLServer"
          # Use SMO Server object from the SqlServer module
          $serverObject = New-Object Microsoft.SqlServer.Management.Smo.Server($SQLServer)

          # Check connection - accessing a property forces connection attempt
          $null = $serverObject.VersionString
          Write-Verbose "Successfully connected to $($serverObject.Name) (Version: $($serverObject.VersionString))"

          # Let the foreach loop handle output collection - more efficient than +=
          foreach ($db in $serverObject.Databases) {

              # Skip system databases if requested
              if ($ExcludeSystemDatabases -and $db.IsSystemObject) {
                  Write-Verbose "Skipping system database: $($db.Name)"
                  continue # Skip to the next database
              }

              Write-Verbose "Processing database: $($db.Name)"

              # Use [DateTime]::MinValue for comparison and ternary operator for cleaner assignment
              $lastFull = if ($db.LastBackupDate -eq $minDate) { 'NEVER' } else { $db.LastBackupDate }
              $lastDiff = if ($db.LastDifferentialBackupDate -eq $minDate) { 'NEVER' } else { $db.LastDifferentialBackupDate }
              $lastLog = if ($db.LastLogBackupDate -eq $minDate) { 'NEVER' } else { $db.LastLogBackupDate }

              # Output a custom object using preferred syntax
              [PSCustomObject]@{
                  Server           = $serverObject.Name # Use the actual connected server name
                  Database         = $db.Name
                  LastFullBackup   = $lastFull
                  LastDiffBackup   = $lastDiff
                  LastLogBackup    = $lastLog
              }
          } # End foreach database

      }
      catch {
          # Provide more context in the error message
          Write-Error "Error processing SQL Server instance '$SQLServer'. Message: $($_.Exception.GetBaseException().Message)"
          # Optionally 'continue' if processing multiple servers via pipeline and want to skip just the failed one
          # Or 'return' to stop processing for this specific server instance from the pipeline input
          return
      }
      finally {
          # Ensure disconnection happens even if errors occurred (if connected)
          if ($null -ne $serverObject -and $serverObject.ConnectionContext.IsOpen) {
              try {
                  Write-Verbose "Disconnecting from SQL Server instance: $($serverObject.Name)"
                  $serverObject.ConnectionContext.Disconnect()
              } catch {
                   Write-Warning "Failed to disconnect from '$($serverObject.Name)'. Message: $($_.Exception.GetBaseException().Message)"
              }
          }
      }
  } # End Process block

  End {
      Write-Verbose "Finished processing all provided SQL Server instances."
  }
}

# Example Usage:
# Show-LastServerBackup -SQLServer "YourServerName" -Verbose
# Show-LastServerBackup -SQLServer "YourServerName\YourInstance" -ExcludeSystemDatabases | Format-Table -AutoSize
# "Server1", "Server2\SQLEXPRESS" | Show-LastServerBackup | Export-Csv -Path "C:\temp\backup_status.csv" -NoTypeInformation