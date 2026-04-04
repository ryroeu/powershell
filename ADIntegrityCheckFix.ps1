<#
.SYNOPSIS
    Manages active directory integrity check fix.
#>

Write-Output "Checking the NTDS database for errors (semantic database analysis) `r "
Stop-Service ntds -force
$NTDSdbChecker = ntdsutil "activate instance ntds" "semantic database analysis" "verbose on" "Go Fixup" q q
Write-Output "Results of Active Directory database integrity check: `r "
$NTDSdbChecker
Start-Service ntds -force