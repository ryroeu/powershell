<#
.SYNOPSIS
Searches Active Directory domains for duplicate address values across core, Exchange, and SIP attributes.

.EXAMPLE
.\Find-DuplicateValues.ps1 -Credential (Get-Credential) -Address john@contoso.com -IncludeExchange
Prompt for credentials and search all domains in forest for default and Exchange attributes that contain john@contoso.com.

.EXAMPLE
.\Find-DuplicateValues.ps1 -Address john@contoso.com -IncludeExchange -IncludeSIP
Search all domains in forest for default, Exchange, and SIP attributes that contain john@contoso.com.

.EXAMPLE
.\Find-DuplicateValues.ps1 -Credential $cred -Address john@contoso.com -IncludeSIP
Search all domains in forest for default and SIP attributes using saved credential object $cred.
#>
function Find-DuplicateValues {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,HelpMessage='Object address to search for, in the form of user@domain.com')]
            [string]$Address,
        [Parameter(Mandatory=$false,HelpMessage='Autodetect schema classes')]
            [switch]$AutoDetect,
        [Parameter(Mandatory=$false,HelpMessage='Credential')]
            [object]$Credential,
        [Parameter(Mandatory=$false,HelpMessage='Include Exchange Attributes')]
            [switch]$IncludeExchange,
        [Parameter(Mandatory=$false,HelpMessage='Include RTC attributes (Live Communications Server, Office Communications Server, Lync, Skype')]
            [switch]$IncludeSIP,
        [Parameter(Mandatory=$false,HelpMessage='Specify output color')]
            [ValidateSet("Black","DarkBlue","DarkGreen","DarkCyan","DarkRed","DarkMagenta","DarkYellow","Gray","DarkGray","Blue","Green","Cyan","Red","Magenta","Yellow","White")]        
            [string]$OutputColor = "Cyan",
        [Parameter(Mandatory=$false,HelpMessage='LDAP Style--will result in partial matches')]
            [switch]$LDAPStyle
    )
    filter FormatColor {
        param(
            [string] $StringMatch,
            [string] $HighlightColor = $OutputColor
        )
        $line = $_
        $index = $line.IndexOf($StringMatch, [System.StringComparison]::InvariantCultureIgnoreCase)
        while($index -ge 0){
            Write-Host $line.Substring(0,$index) -NoNewline
            Write-Host $line.Substring($index, $StringMatch.Length) -NoNewline -ForegroundColor $OutputColor
            $used = $StringMatch.Length + $index
            $remain = $line.Length - $used
            $line = $line.Substring($used, $remain)
            $index = $line.IndexOf($StringMatch, [System.StringComparison]::InvariantCultureIgnoreCase)
        }
        Write-Host $line
    }
    If ($AutoDetect){
        $schema = [directoryservices.activedirectory.activedirectoryschema]::getcurrentschema()
        $ExchTest = $schema.FindClass("user").OptionalProperties | Where-Object {$_.Name -match "msExchRecipientTypeDetails"}
        $SIPTest = $schema.FindClass("user").OptionalProperties | Where-Object {$_.Name -match "msRTCSIP-PrimaryUserAddress"}
        If ($ExchTest){
            $IncludeExchange = $true ; Write-Host "Found Exchange Attributes."
        }
        If ($SIPTest){
            $IncludeSIP = $true; Write-Host "Found SIP Attributes."
        }
    }
    If (!(Get-Module ActiveDirectory)){
        Import-Module ActiveDirectory
    }

    [array]$Forests = (Get-ADForest).Domains
    [array]$Attributes = @("UserPrincipalName","DisplayName","DistinguishedName","objectClass","mail")

    $global:FormatEnumerationLimit = -1

    # Add Additional Arrays together
    If ($IncludeExchange){
        $ExchangeAttributes = @("proxyAddresses","msExchRecipientDisplayType","msExchRecipientTypeDetails","mailnickname","targetAddress")
        $Attributes += $ExchangeAttributes
    }
    If ($IncludeSIP){
        $SIPAttributes = @("msRTCSIP-PrimaryUserAddress")
        $Attributes += $SIPAttributes
    }
    If ($LDAPStyle){
        # Build LDAP Filter
        [string]$LDAPFilter = "(&(|(objectClass=user)(objectClass=group)(objectClass=contact))(|(userprincipalname=$address)(mail=*$address)))"
        If ($IncludeExchange){
            $LDAPFilter = $LDAPFilter.Substring(0,$LDAPFilter.Length -2) + "(proxyaddresses=*$address)(targetaddress=smtp:$address)))"
        }
        If ($IncludeSIP){
            $LDAPFilter = $LDAPFilter.Substring(0,$LDAPFilter.Length -2) + "(msRTCSIP-PrimaryUserAddress=*$address)))"
        }
        If ($Credential){
            Foreach ($Domain in $Forests){
                Write-Host -ForegroundColor Yellow "Searching $Domain for $address"
                Get-AdObject -Credential $Credential -Server $Domain -LDAPFilter $LDAPFilter -Properties $Attributes| Select-Object $Attributes | Out-String | FormatColor -StringMatch $($address) -HighlightColor $($Color)
            }
        }
        Else {
            Foreach ($Domain in $Forests){
                Write-Host -ForegroundColor Yellow "Searching $Domain for $address"
                Get-AdObject -Server $Domain -LDAPFilter $LDAPFilter -Properties $Attributes| Select-Object $Attributes | Out-String | FormatColor -StringMatch $($address) -HighlightColor $($Color)
            }
        }
    }
    Else {
        $Filter = [scriptblock]::Create("`{ UserPrincipalName -eq `"$address`" -or mail -eq `"$address`" `}")
        If ($IncludeExchange){
            $Filter = [scriptblock]::Create("`{ Userprincipalname -eq `"$address`" -or mail -eq `"$address`" -or proxyAddresses -like `"`*`:$address`" `}")
        }
        If ($IncludeSIP){
            $Filter = [scriptblock]::Create("`{ Userprincipalname -eq `"$address`" -or mail -eq `"$address`" -or msRTCSIP-PrimaryUserAddress -like `"`*`:$address`" `}")
        }
        If ($IncludeExchange -and $IncludeSIP){
            $Filter = [scriptblock]::Create("`{ Userprincipalname -eq `"$address`" -or mail -eq `"$address`" -or msRTCSIP-PrimaryUserAddress -like `"`*`:$address`" -or proxyAddresses -like `"`*`:$address`" `}") 
        }
        Foreach ($Domain in $Forests){
            Write-Host "Using Filter $($Filter)"
            If ($Credential){
                $cmd = "Get-ADObject -Credential `$Credential -Server $Domain -Filter $Filter -Properties * | Select `$Attributes | Out-String | FormatColor -StringMatch $($address) -HighlightColor `$($Color)"
            }
            Else {
                $cmd = "Get-ADObject -Server $Domain -Filter $Filter -Properties * | Select `$Attributes | Out-String | FormatColor -StringMatch $($address) -HighlightColor `$($Color)"
            }
            Write-Host -ForegroundColor Yellow "Searching $Domain for $address"
            Invoke-Expression $cmd
        }
    }
}
