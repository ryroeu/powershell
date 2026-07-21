<#
.SYNOPSIS
    Finds files whose cryptographic hash matches a reference file.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ReferencePath,

    [Parameter(Mandatory)]
    [string]$SearchPath,

    [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
    [string]$Algorithm = 'SHA256',

    [switch]$Recurse
)

$reference = Get-Item -LiteralPath $ReferencePath -ErrorAction Stop
$referenceHash = (Get-FileHash -LiteralPath $reference.FullName -Algorithm $Algorithm).Hash

Get-ChildItem -LiteralPath $SearchPath -File -Recurse:$Recurse |
    Where-Object FullName -NE $reference.FullName |
    ForEach-Object {
        $candidateHash = (Get-FileHash -LiteralPath $_.FullName -Algorithm $Algorithm).Hash
        if ($candidateHash -eq $referenceHash) {
            [pscustomobject]@{
                Path      = $_.FullName
                Algorithm = $Algorithm
                Hash      = $candidateHash
            }
        }
    }
