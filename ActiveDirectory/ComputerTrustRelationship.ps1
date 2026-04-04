<#
.SYNOPSIS
    Manages computer trust relationship.
#>

### Test and Repair Trust Relationship ###
Test-ComputerSecureChannel -Server "domain.com" `
                           -Repair `
                           -Verbose