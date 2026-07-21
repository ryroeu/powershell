<#
.SYNOPSIS
    Exports a certificate and private key to a password-protected PFX file.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

    [Parameter(Mandatory)]
    [string]$FilePath,

    [Parameter(Mandatory)]
    [securestring]$Password,

    [switch]$ChainOptionBuildChain
)

process {
    if (-not $Certificate.HasPrivateKey) {
        throw "Certificate '$($Certificate.Thumbprint)' has no private key to export."
    }

    if ($PSCmdlet.ShouldProcess($FilePath, "Export certificate $($Certificate.Thumbprint) to PFX")) {
        $parameters = @{
            Cert     = $Certificate
            FilePath = $FilePath
            Password = $Password
            Force    = $true
        }
        if ($ChainOptionBuildChain) { $parameters.ChainOption = 'BuildChain' }
        Export-PfxCertificate @parameters
    }
}
