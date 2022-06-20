Function Show-LastServerBackup ($SQLServer) {
  $server = new-object "Microsoft.SqlServer.Management.Smo.Server" $SQLServer
  $Results = @();
  foreach($db in $server.Databases) {
    $DBName = $db.name
    $LastFull = $db.lastbackupdate
    if($lastfull -eq '01 January 0001 00:00:00')
      {$LastFull = 'NEVER'}
      $LastDiff = $db.LastDifferentialBackupDate  
    if($lastdiff -eq '01 January 0001 00:00:00')
      {$Lastdiff = 'NEVER'}
      $lastLog = $db.LastLogBackupDate 
    if($lastlog -eq '01 January 0001 00:00:00')
      {$Lastlog= 'NEVER'}
      $TempResults = New-Object PSObject;
      $TempResults | Add-Member -MemberType NoteProperty -Name "Server" -Value $Server;
      $TempResults | Add-Member -MemberType NoteProperty -Name "Database" -Value $DBName;
      $TempResults | Add-Member -MemberType NoteProperty -Name "Last Full Backup" -Value $LastFull;
      $TempResults | Add-Member -MemberType NoteProperty -Name "Last Diff Backup" -Value $LastDiff;
      $TempResults | Add-Member -MemberType NoteProperty -Name "Last Log Backup" -Value $LastLog;
      $Results += $TempResults;
  }
$Results|Format-Table -auto
}