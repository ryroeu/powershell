<#
.SYNOPSIS
    Stops service.
#>

$ServiceName = 'Name of Service'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -eq 'Running') {
    Stop-Service $ServiceName
    Write-Host $arrService.status
    Write-Host 'Service stopping'
    Start-Sleep -Seconds 60
    $arrService.Refresh()
    if ($arrService.Status -ne 'Running') {
        Write-Host 'Service is now Stopped'
    }
    else {
        Write-Host "Service could not be Stopped"
    }
}