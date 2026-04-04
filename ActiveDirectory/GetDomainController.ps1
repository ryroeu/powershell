<#
.SYNOPSIS
    Retrieves domain controller.
#>

# Get Primary Domain Controller
(Get-ADDomain).PDCEmulator
