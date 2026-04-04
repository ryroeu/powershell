<#
.SYNOPSIS
    Creates remote description.
#>

$myDescription = "ComputerName"
Invoke-Command -ComputerName $lServerName -ScriptBlock {
    Set-CimInstance -Query "SELECT * FROM Win32_OperatingSystem" -Property @{ Description = $args[0] }
} -ArgumentList $myDescription
