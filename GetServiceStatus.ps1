$svc = Get-Service W32Time
$svcName = $svc.Name
switch -wildcard ($svc.Status) {
    "S*" {Write-Host "The $svcName service is stopped."}
    "R*" {Write-Host "The $svcName service is running."}
    "P*" {Write-Host "The $svcName service is paused."}
    default {Write-Host "Check the service."}
}
