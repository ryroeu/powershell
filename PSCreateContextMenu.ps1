<#
.SYNOPSIS
    Creates PowerShell context menu.
#>

New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
New-ItemProperty 'HKCR:\Microsoft.PowerShellScript.1\Shell\Run with PowerShell (Admin)' -Name 'Run with PowerShell'
New-ItemProperty 'HKCR:\Microsoft.PowerShellScript.1\Shell\Run with PowerShell (Admin)\Command' -Name 'Run with PowerShell'
Set-ItemProperty 'HKCR:\Microsoft.PowerShellScript.1\Shell\Run with PowerShell (Admin)\Command' '(Default)' '"C:\Program Files\PowerShell\7\pwsh.exe" "-Command" ""& {Start-Process PowerShell.exe -ArgumentList ''-ExecutionPolicy Unrestricted -File \"%1\"'' -Verb RunAs}"'