<#
.SYNOPSIS
    Exports a Windows event log from remote computers to a central directory.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name')]
    [string[]]$ComputerName,

    [string]$LogName = 'Application',

    [string]$RemoteDirectory = 'C:\Logs',

    [Parameter(Mandatory)]
    [string]$DestinationDirectory,

    [pscredential]$Credential
)

process {
    $null = New-Item -ItemType Directory -Path $DestinationDirectory -Force
    foreach ($computer in $ComputerName) {
        $fileName = '{0}_{1}_{2:yyyyMMdd_HHmmss}.evtx' -f $computer, $LogName, (Get-Date)
        $remotePath = Join-Path $RemoteDirectory $fileName
        if (-not $PSCmdlet.ShouldProcess($computer, "Export '$LogName' event log to '$DestinationDirectory'")) {
            continue
        }

        $sessionParameters = @{ ComputerName = $computer }
        if ($Credential) {
            $sessionParameters.Credential = $Credential
        }
        $session = New-PSSession @sessionParameters
        try {
            Invoke-Command -Session $session -ScriptBlock {
                $eventLogName = $using:LogName
                $directory = $using:RemoteDirectory
                $path = $using:remotePath
                $null = New-Item -ItemType Directory -Path $directory -Force
                & wevtutil.exe epl $eventLogName $path /ow:true
                if ($LASTEXITCODE -ne 0) {
                    throw "wevtutil.exe failed with exit code $LASTEXITCODE."
                }
            }
            Copy-Item -FromSession $session -LiteralPath $remotePath -Destination (Join-Path $DestinationDirectory $fileName) -Force
            Invoke-Command -Session $session -ScriptBlock {
                Remove-Item -LiteralPath $using:remotePath -Force
            }
        }
        finally {
            Remove-PSSession -Session $session
        }
    }
}
