<#
.SYNOPSIS
    Creates certificate on remote pc.
#>

function New-RemoteRDPCertificate {
    <#
        .SYNOPSIS
            Creates a new self-signed certificate on a remote Windows computer and binds it to RDP.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByComputerName', PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([psobject])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByComputerName', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPSSession', ValueFromPipeline = $true)]
        [System.Management.Automation.Runspaces.PSSession]$PSSession,

        [Parameter()]
        [ValidateNotNull()]
        [datetime]$ValidUntil = (Get-Date).AddYears(1),

        [Parameter()]
        [ValidateSet('SHA256', 'SHA384', 'SHA512')]
        [string]$HashAlgorithm = 'SHA256',

        [Parameter()]
        [ValidateSet(2048, 4096, 8192, 16384)]
        [int]$KeyLength = 2048,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        $createdSession = $false
        if ($PSBoundParameters.ContainsKey('ComputerName')) {
            $PSSession = New-PSSession -ComputerName $ComputerName
            $createdSession = $true
        }
    }

    process {
        $targetName = if ($ComputerName) { $ComputerName } else { $PSSession.ComputerName }

        if (-not $PSCmdlet.ShouldProcess($targetName, 'Create and assign a new self-signed RDP certificate')) {
            return
        }

        $result = Invoke-Command -Session $PSSession -HideComputerName -ArgumentList $ValidUntil, $HashAlgorithm, $KeyLength -ScriptBlock {
            param(
                [datetime]$using:using:ValidUntil,
                [string]$using:using:Algorithm,
                [int]$using:using:KeyLength
            )

            Add-Type -AssemblyName System.Security

            $extensions = [System.Collections.Generic.List[object]]::new()

            $ekuOids = New-Object -ComObject 'X509Enrollment.CObjectIds.1'
            $serverAuthOid = New-Object -ComObject 'X509Enrollment.CObjectId.1'
            $eku = [System.Security.Cryptography.Oid]::FromFriendlyName('Server Authentication', [System.Security.Cryptography.OidGroup]::EnhancedKeyUsage)
            $serverAuthOid.InitializeFromValue($eku.Value)
            $ekuOids.Add($serverAuthOid)

            $ekuExtension = New-Object -ComObject 'X509Enrollment.CX509ExtensionEnhancedKeyUsage.1'
            $ekuExtension.InitializeEncode($ekuOids)
            $extensions.Add($ekuExtension)

            $keyUsage = New-Object -ComObject 'X509Enrollment.CX509ExtensionKeyUsage.1'
            $keyUsage.InitializeEncode(48)
            $keyUsage.Critical = $false
            $extensions.Add($keyUsage)

            $basicConstraints = New-Object -ComObject 'X509Enrollment.CX509ExtensionBasicConstraints.1'
            $basicConstraints.InitializeEncode($false, -1)
            $basicConstraints.Critical = $true
            $extensions.Add($basicConstraints)

            $key = New-Object -ComObject 'X509Enrollment.CX509PrivateKey.1'
            $algorithmId = New-Object -ComObject 'X509Enrollment.CObjectId.1'
            $publicKeyAlgorithm = [System.Security.Cryptography.Oid]::FromFriendlyName('RSA', [System.Security.Cryptography.OidGroup]::PublicKeyAlgorithm)
            $algorithmId.InitializeFromValue($publicKeyAlgorithm.Value)

            $key.ProviderName = 'Microsoft RSA SChannel Cryptographic Provider'
            $key.Algorithm = $algorithmId
            $key.KeySpec = 1
            $key.Length = $KeyLength
            $key.SecurityDescriptor = 'D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)'
            $key.MachineContext = 1
            $key.ExportPolicy = 0
            $key.Create()

            $subject = New-Object -ComObject 'X509Enrollment.CX500DistinguishedName.1'
            $subject.Encode(("CN={0}" -f $env:COMPUTERNAME), 0)

            $request = New-Object -ComObject 'X509Enrollment.CX509CertificateRequestCertificate.1'
            $request.InitializeFromPrivateKey(2, $key, [string]::Empty)
            $request.Subject = $subject
            $request.Issuer = $request.Subject
            $request.NotBefore = Get-Date
            $request.NotAfter = $ValidUntil

            foreach ($extension in $extensions) {
                $request.X509Extensions.Add($extension)
            }

            $signatureId = New-Object -ComObject 'X509Enrollment.CObjectId.1'
            $hashAlgorithm = [System.Security.Cryptography.Oid]::FromFriendlyName($Algorithm, [System.Security.Cryptography.OidGroup]::HashAlgorithm)
            $signatureId.InitializeFromValue($hashAlgorithm.Value)
            $request.SignatureInformation.HashAlgorithm = $signatureId
            $request.Encode()

            $enrollment = New-Object -ComObject 'X509Enrollment.CX509Enrollment.1'
            $enrollment.CertificateFriendlyName = '{0} RDP' -f $env:COMPUTERNAME
            $enrollment.InitializeFromRequest($request)

            $requestBlob = $enrollment.CreateRequest(1)
            $enrollment.InstallResponse(2, $requestBlob, 1, [string]::Empty)

            [byte[]]$certificateBytes = [System.Convert]::FromBase64String($requestBlob)
            $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificateBytes)

            $rdpSettings = Get-CimInstance -Namespace 'root\cimv2\TerminalServices' -ClassName 'Win32_TSGeneralSetting' -Filter 'TerminalName = "RDP-Tcp"'
            $rdpSettings | Set-CimInstance -Property @{ SSLCertificateSHA1Hash = $certificate.Thumbprint } | Out-Null

            [pscustomobject]@{
                ComputerName = $env:COMPUTERNAME
                Thumbprint   = $certificate.Thumbprint
                NotAfter     = $certificate.NotAfter
                Certificate  = $certificate
            }
        }

        if ($PassThru) {
            Write-Output $result -NoEnumerate
        }
    }

    end {
        if ($createdSession -and $PSSession) {
            Remove-PSSession -Session $PSSession
        }
    }
}
