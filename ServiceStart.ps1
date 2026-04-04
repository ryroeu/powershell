<#
.SYNOPSIS
    Starts service.
#>

$ServiceName = 'Name of Service'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{

    Start-Service $ServiceName
    write-host $arrService.status
    write-host 'Service starting'
    Start-Sleep -seconds 60
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
    }
    else
    {
        Write-Host "Service could not be Started"
    }

}