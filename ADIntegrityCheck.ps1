<#
.SYNOPSIS
    Manages active directory integrity check.
#>

Write-Output "Checking the NTDS database for errors (semantic database analysis) `r "
Stop-Service ntds -force
$NTDSdbChecker = ntdsutil "activate instance ntds" "semantic database analysis" "verbose on" "Go" q q
Write-Output "Results of Active Directory database integrity check: `r "
$NTDSdbChecker
Start-Service ntds -force