<#
.SYNOPSIS
    Retrieves computer information.
#>

function Get-PCinfo {
    Write-Host "Getting OS Info.." -ForegroundColor Magenta
    systeminfo | findstr /B /C:"OS Name" /B /C:"OS Version" | Format-Table -AutoSize

    Write-Host "Getting LoggedOn User.." -ForegroundColor Magenta
    Get-CimInstance Win32_LoggedOnUser | Select-Object PSComputerName, Antecedent, Dependent | Format-Table -AutoSize

    Write-Host "Getting BIOS Version.." -ForegroundColor Magenta
    Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate, SerialNumber | Format-Table -AutoSize

    Write-Host "Getting CPU Info.." -ForegroundColor Magenta
    Get-CimInstance Win32_Processor | Select-Object Name, MaxClockSpeed, NumberOfCores | Format-Table -AutoSize

    Write-Host "Getting 10 highest processes on CPU Usage.." -ForegroundColor Magenta
    Get-Process | Where-Object Path -notlike ($env:WINDIR + "*") | Sort-Object CPU | Select-Object Name, CPU, StartTime | Select-Object -Last 10 | Sort-Object CPU -Descending | Format-Table -AutoSize

    Write-Host "Getting Disk info.." -ForegroundColor Magenta
    Get-Disk | Format-Table -AutoSize

    Write-Host "Getting Disk Status.." -ForegroundColor Magenta
    Get-Volume | Where-Object DriveLetter -EQ "C" | Format-Table -AutoSize

    Write-Host "Getting Network Adapter info.." -ForegroundColor Magenta
    Get-NetAdapter | Sort-Object Name | Format-Table -AutoSize

    Write-Host "Getting Network Connection info.." -ForegroundColor Magenta
    Get-NetConnectionProfile | Select-Object Name, InterfaceAlias, IPv4Connectivity, IPv6Connectivity, NetworkCategory | Format-Table -AutoSize

    Write-Host "Getting IPv4 Addresses.." -ForegroundColor Magenta
    Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress | Sort-Object InterfaceAlias | Format-Table -AutoSize

    Write-Host "Getting DNS IPv4 info.." -ForegroundColor Magenta
    Get-DnsClientServerAddress -AddressFamily IPv4 | Sort-Object InterfaceAlias | Format-Table -AutoSize

    Write-Host "Getting IPv6 Addresses.." -ForegroundColor Magenta
    Get-NetIPAddress -AddressFamily IPv6 | Select-Object InterfaceAlias, IPAddress | Sort-Object InterfaceAlias | Format-Table -AutoSize

    Write-Host "Getting DNS IPv6 info.." -ForegroundColor Magenta
    Get-DnsClientServerAddress -AddressFamily IPv6 | Sort-Object InterfaceAlias | Format-Table -AutoSize

    Write-Host "Getting Licensing Status.."  -ForegroundColor Magenta
    cscript C:\Windows\System32\slmgr.vbs /dlv
}
Get-PCinfo
Read-Host -Prompt "Press Enter to exit"