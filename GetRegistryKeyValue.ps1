<#
.SYNOPSIS
    Retrieves registry key value.
#>

# Check Registry Key
$RegistryKey = Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name "WUServer" -ErrorAction Ignore
if ($RegistryKey -EQ "https://SERVERNAME.DOMAIN.COM:8531") {
    Write-Host "Registry Key Found"
}
else {
    Write-Host "Registry Key Not Found"
}
