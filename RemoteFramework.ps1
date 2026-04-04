<#
.SYNOPSIS
    Manages remote framework.
#>

#requires -version 5.1

<#
This is a function template that utilizes remoting to get or do something from
remote computers. The framework is written to support both Windows PowerShell
and remoting with SSH in PowerShell 7. It defines dynamic parameters for
PwoerShell 7. You may decide to re-define them as normal parameters.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED.
#>

#TODO: DEFINE A VALID COMMAND NAME
Function Get-RemoteFramework {

    #TODO: Create help documentation for your command

    [cmdletbinding(DefaultParameterSetName = "computer")]
    #TODO: Add and modify parameters as necessary
    Param(
        [Parameter(
            ParameterSetName = "computer",
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter the name of a computer to query. The default is the local host."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("cn")]
        [string[]]$ComputerName,
        [Parameter(
            ParameterSetName = "computer",
            HelpMessage = "Enter a credential object or username."
        )]
        [Alias("RunAs")]
        [PSCredential]$Credential,
        [Parameter(ParameterSetName = "computer")]
        [switch]$UseSSL,

        [Parameter(
            ParameterSetName = "session",
            ValueFromPipeline
            )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,

        [ValidateScript( {$_ -ge 0})]
        [int32]$ThrottleLimit = 32
    )
    DynamicParam {
        #Add an SSH dynamic parameter if in PowerShell 7
        if ($isCoreCLR) {

            $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

            #a CSV file with dynamic parameters to create
            #this approach doesn't take any type of parameter validation into account
            $data = @"
Name,Type,Mandatory,Default,Help
HostName,string[],1,,"Enter the remote host name."
UserName,string,0,,"Enter the remote user name."
Subsystem,string,0,"powershell","The name of the ssh subsystem. The default is powershell."
Port,int32,0,,"Enter an alternate SSH port"
KeyFilePath,string,0,,"Specify a key file path used by SSH to authenticate the user"
SSHTransport,switch,0,,"Use SSH to connect."
"@

            $data | ConvertFrom-Csv | ForEach-Object -begin { } -process {
                $attributes = New-Object System.Management.Automation.ParameterAttribute
                $attributes.Mandatory = ([int]$_.mandatory) -as [bool]
                $attributes.HelpMessage = $_.Help
                $attributes.ParameterSetName = "SSH"
                $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection.Add($attributes)
                $dynParam = New-Object -Type System.Management.Automation.RuntimeDefinedParameter($_.name, $($_.type -as [type]), $attributeCollection)
                $dynParam.Value = $_.Default
                $paramDictionary.Add($_.name, $dynParam)
            } -end {
                return $paramDictionary
            }
        }
    } #dynamic param

    Begin {
        #capture the start time. The Verbose messages can display a timespan.
        $start = Get-Date
        #the first verbose message uses a pseudo timespan to reflect the idea we're just starting
        Write-Verbose "[00:00:00.0000000 BEGIN  ] Starting $($myinvocation.mycommand)"

        #a script block to be run remotely
        Write-Verbose "[$(New-TimeSpan -start $start) BEGIN  ] Defining the scriptblock to be run remotely."

        #TODO: define the scriptblock to be run remotely
        $sb = {
            param([string]$VerbPref = "SilentlyContinue", [bool]$WhatPref)

            $VerbosePreference = $VerbPref
            $WhatIfPreference = $WhatPref
            #TODO: add verbose messaging
            #the timespan assumes an accurate clock on the remote computer
            Write-Verbose "[$(New-TimeSpan -start $using:start) REMOTE ] Doing something remotely on $([System.Environment]::MachineName)."

            "[$([System.Environment]::MachineName)] Hello, World"

        } #scriptblock

        #parameters to splat to Invoke-Command
        Write-Verbose "[$(New-TimeSpan -start $start) BEGIN  ] Defining parameters for Invoke-Command."

        #TODO: Update arguments as needed. This framework assumes any arguments are NOT coming through the pipeline and will be the same for all remote computers
        #TODO: You will need to handle parameters like -WhatIf that you want to pass remotely

        $icmParams = @{
            Scriptblock      = $sb
            Argumentlist     = $VerbosePreference, $WhatIfPreference
            HideComputerName = $False
            ThrottleLimit    = $ThrottleLimit
            ErrorAction      = "Stop"
            Session          = $null
        }

        #initialize an array to hold session objects
        [System.Management.Automation.Runspaces.PSSession[]]$All = @()

        If ($Credential.username) {
            Write-Verbose "[$(New-TimeSpan -start $start) BEGIN  ] Using alternate credential for $($credential.username)."
        }

    } #begin

    Process {
        Write-Verbose "[$(New-TimeSpan -start $start) PROCESS] Detected parameter set $($pscmdlet.ParameterSetName)."
        Write-Verbose "[$(New-TimeSpan -start $start) PROCESS] Detected PSBoundParameters:`n$($PSBoundParameters | Out-String)"

        $remotes = @()
        if ($PSCmdlet.ParameterSetName -match "computer|ssh") {
            if ($pscmdlet.ParameterSetName -eq 'ssh') {
                $remotes += $PSBoundParameters.HostName
                $param = "HostName"
            }
            else {
                $remotes += $PSBoundParameters.ComputerName
                $param = "ComputerName"
            }

            foreach ($remote in $remotes) {
                $PSBoundParameters[$param] = $remote
                $PSBoundParameters["ErrorAction"] = "Stop"
                Try {
                    #create a session one at a time to better handle errors
                    Write-Verbose "[$(New-TimeSpan -start $start) PROCESS] Creating a temporary PSSession to $remote."
                    #save each created session to $tmp so it can be removed at the end
                    #TODO: If your function will add parameters they will need to be removed from $PSBoundParamters or you will need to adjust the the command to create the New-PSSession
                    $all += New-PSSession @PSBoundParameters -OutVariable +tmp
                } #Try
                Catch {
                    #TODO: Decide what you want to do when the new session fails
                    Write-Warning "Failed to create session to $remote. $($_.Exception.Message)."
                    #Write-Error $_
                } #catch
            } #foreach remote
        }
        Else {
            #only add open sessions
            foreach ($sess in $session) {
                if ($sess.state -eq 'opened') {
                    Write-Verbose "[$(New-TimeSpan -start $start) PROCESS] Using session for $($sess.ComputerName.toUpper())."
                    $all += $sess
                } #if open
            } #foreach session
        } #else sessions
    } #process

    End {

        $icmParams["session"] = $all

        Try {
            Write-Verbose "[$(New-TimeSpan -start $start) END    ] Querying $($all.count) computers."

            Invoke-Command @icmParams | ForEach-Object {
                #TODO: PROCESS RESULTS FROM EACH REMOTE CONNECTION IF NECESSARY
                $_
            } #foreach result
        } #try
        Catch {
            Write-Error $_
        } #catch

        if ($tmp) {
            Write-Verbose "[$(New-TimeSpan -start $start) END    ] Removing $($tmp.count) temporary PSSessions."
            $tmp | Remove-PSSession
        }
        Write-Verbose "[$(New-TimeSpan -start $start) END    ] Ending $($myinvocation.mycommand)"
    } #end
} #close function