<#
.SYNOPSIS
    Resizes resize.
#>

$MaxSize = (Get-PartitionSupportedSize -DriveLetter c).sizeMax
Resize-Partition -DriveLetter c -Size $MaxSize