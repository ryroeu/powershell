<#
.SYNOPSIS
    Installs one or more Windows Server roles or features.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Name,

    [string]$ComputerName = $env:COMPUTERNAME,

    [switch]$IncludeManagementTools,

    [switch]$Restart
)

$parameters = @{
    Name                   = $Name
    IncludeManagementTools = $IncludeManagementTools
    Restart                = $Restart
}

if ($ComputerName -and $ComputerName -notin '.', 'localhost', $env:COMPUTERNAME) {
    $parameters.ComputerName = $ComputerName
}

if ($PSCmdlet.ShouldProcess($ComputerName, "Install Windows feature(s): $($Name -join ', ')")) {
    Install-WindowsFeature @parameters
}
