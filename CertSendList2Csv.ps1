Set-Location Cert:
Start-Sleep 1
Get-ChildItem -recurse | Export-CSV "C:\MLCerts.csv"
Start-Sleep 1
Invoke-Item "C:\MLCerts.csv"