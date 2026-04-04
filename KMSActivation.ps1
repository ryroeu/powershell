<#
.SYNOPSIS
    Manages kms activation.
#>

### Description: This script will activate Windows Server 2022 Standard LTSC using KMS ###
# Install Key
slmgr.vbs /ipk 'WX4NM-KYWYW-QJJR4-XV3QB-6VM33'
# Activate
slmgr /ato
# Check Activation Status
slmgr /dlv