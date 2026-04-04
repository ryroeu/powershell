<#
.SYNOPSIS
Moves a computer from a source domain to a target domain and restarts it after the domain join.

The variables $computerSAM and $fqdn come from the main part of the script as parameters when calling the function.
$computerSAM=”samaccountname of computer to migrate”
$fqdn=”full qualified domain name of computer to migrate”
The text files with the encrypted passwords are located in the same directory as the executable or ps1 script.
#>
function domain_move($computerSAM,$fqdn) {
    $username_joinTarget=”TARGETDOMAIN\SERVICEACCOUNT”
    $password_joinTarget=cat“d:\scripts\server_move\JoinTarget.txt”|convertto-securestring
    $cred_JoinTarget=new-object -typename System.Management.Automation.PSCredential –argumentlist $username_joinTarget,$password_joinTarget
    $username_unjoinSource=”SOURCEDOMAIN\SERVICEACCOUNT”
    $password_unjoinSource=cat“d:\scripts\server_move\UnjoinSource.txt”|convertto-securestring
    $cred_UnjoinSource=new-object -typename System.Management.Automation.PSCredential -argumentlist $username_unjoinSource,$password_unjoinSource
    $Error.clear
    Try {Add-Computer -ComputerName $computerSAM -DomainName $TARGETDOMAIN -Credential $cred_JoinTarget -UnjoinDomainCredential $cred_UnJoinSource -Server $TargetDC -PassThru -Verbose}
    Catch {return $false}
    Start-Sleep -Seconds 10
    Restart-Computer -ComputerName $fqdn
    return $true
}
