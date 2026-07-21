<#
.SYNOPSIS
    Keeps UAC enabled while configuring elevation prompts.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateSet(0, 1, 2, 3, 4, 5)]
    [int]$AdministratorPromptBehavior = 5,

    [ValidateSet(0, 1, 3)]
    [int]$StandardUserPromptBehavior = 3,

    [bool]$PromptOnSecureDesktop = $true
)

$path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
if ($PSCmdlet.ShouldProcess('Local computer', 'Configure UAC prompt behavior')) {
    Set-ItemProperty -LiteralPath $path -Name EnableLUA -Value 1 -Type DWord
    Set-ItemProperty -LiteralPath $path -Name ConsentPromptBehaviorAdmin -Value $AdministratorPromptBehavior -Type DWord
    Set-ItemProperty -LiteralPath $path -Name ConsentPromptBehaviorUser -Value $StandardUserPromptBehavior -Type DWord
    Set-ItemProperty -LiteralPath $path -Name PromptOnSecureDesktop -Value ([int]$PromptOnSecureDesktop) -Type DWord
}
