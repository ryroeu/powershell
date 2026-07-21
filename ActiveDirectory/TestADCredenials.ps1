<#
.SYNOPSIS
    Tests a credential against PowerShell remoting endpoints.
#>

[CmdletBinding(DefaultParameterSetName = 'Computer')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Computer', ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name')]
    [string[]]$ComputerName,

    [Parameter(Mandatory, ParameterSetName = 'Path')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ComputerListPath,

    [Parameter(Mandatory)]
    [pscredential]$Credential,

    [switch]$UseSsl
)

begin {
    $targets = [Collections.Generic.List[string]]::new()
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        foreach ($line in Get-Content -LiteralPath $ComputerListPath) {
            if (-not [string]::IsNullOrWhiteSpace($line)) { $targets.Add($line.Trim()) }
        }
    }
}

process {
    foreach ($computer in $ComputerName) {
        if (-not [string]::IsNullOrWhiteSpace($computer)) { $targets.Add($computer.Trim()) }
    }
}

end {
    foreach ($computer in $targets | Sort-Object -Unique) {
        try {
            $result = Invoke-Command -ComputerName $computer -Credential $Credential -UseSSL:$UseSsl -ScriptBlock {
                [pscustomobject]@{ ComputerName = [Environment]::MachineName; PowerShellVersion = $PSVersionTable.PSVersion.ToString() }
            } -ErrorAction Stop
            [pscustomobject]@{ ComputerName = $computer; Authenticated = $true; RemoteResult = $result; Error = $null }
        }
        catch {
            [pscustomobject]@{ ComputerName = $computer; Authenticated = $false; RemoteResult = $null; Error = $_.Exception.Message }
        }
    }
}
