<#
.SYNOPSIS
    Manages oracle remediation mitigate.
#>

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters" -Name AllowEncryptionOracle -Value 2 -Type DWord