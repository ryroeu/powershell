Function New-RemoteRDPCertificate() {    # Kind of redudant; I know... (¬､¬)

    <#
        .SYNOPSIS
            To be used instead of the standard 'Set-RDPCertificate' when you want to create a new
            self-signed certificate on the remote computer.
    #>
    [CmdletBinding(DefaultParameterSetName="ByComputerName", PositionalBinding=$false)]
    [OutputType([psobject])]
    param (
        [parameter(Mandatory=$true, ParameterSetName="ByComputerName", Position=0)]
        [string] $ComputerName,

        [parameter(Mandatory=$true, ParameterSetName="ByPSSession", ValueFromPipeline=$true)]
        [System.Management.Automation.Runspaces.PSSession]
        $PSSession,

        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [datetime] $ValidUntil = [datetime]::Now.AddYears(1),

        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [MG.RDP.Certificates.Algorithm]
        $HashAlgorithm = [MG.RDP.Certificates.Algorithm]::SHA256,

        [parameter(Mandatory=$false)]
        [ValidateSet('2048','4096','8192','16384')]
        [int] $KeyLength = 2048,

        [parameter(Mandatory=$false)]
        [switch] $PassThru
    )
    BEGIN {
        if ($PSBoundParameters["ComputerName"]) {
            $PSSession = New-PSSession -ComputerName $ComputerName
        }
    }
    PROCESS {
        $sessionArgs = @($ValidUntil, $HashAlgorithm.ToString(), $KeyLength)
        $result = Invoke-Command -Session $PSSession -HideComputerName -ArgumentList $sessionArgs -ScriptBlock {
            param (
                [datetime] $using:using:using:validUntil = $args[0],
                [string] $using:using:using:algorithm = $args[1],
                [int] $using:using:using:KeyLength = $args[2]
            )
            Add-Type -AssemblyName System.Security;
            $extsToAdd = New-Object 'System.Collections.Generic.List[object]';

            # Enhanced Key Usage
            $ekuOids = New-Object -com 'X509Enrollment.CObjectIds.1';
            $serverAuthOid = New-Object -com 'X509Enrollment.CObjectId.1';
            $eu = [System.Security.Cryptography.Oid]::FromFriendlyName("Server Authentication", [System.Security.Cryptography.OidGroup]::EnhancedKeyUsage);
            $serverAuthOid.InitializeFromValue($eu.Value);
            $ekuOids.Add($serverAuthOid);
            $ekuExt = New-Object -com 'X509Enrollment.CX509ExtensionEnhancedKeyUsage.1';
            $ekuExt.InitializeEncode($ekuOids);
            $extsToAdd.Add($ekuExt);

            # Key Usage
            $ku = New-Object -com 'X509Enrollment.CX509ExtensionKeyUsage.1';
            $ku.InitializeEncode(48);
            $ku.Critical = $false;
            $extsToAdd.Add($ku);

            # Basic Constraints
            $bc = New-Object -com 'X509Enrollment.CX509ExtensionBasicConstraints.1';
            $bc.InitializeEncode($false, -1);
            $bc.Critical = $true;
            $extsToAdd.Add($bc);

            # Private Key
            $key = New-Object -com 'X509Enrollment.CX509PrivateKey.1';
            $algId = New-Object -com 'X509Enrollment.CObjectId.1';
            $algVal = [System.Security.Cryptography.Oid]::FromFriendlyName("RSA", [System.Security.Cryptography.OidGroup]::PublicKeyAlgorithm);
            $algId.InitializeFromValue($algVal.Value);
            $key.ProviderName = 'Microsoft RSA SChannel Cryptographic Provider';
            $key.Algorithm = $algId;
            $key.KeySpec = 1;
            $key.Length = $KeyLength;
            $key.SecurityDescriptor = 'D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)';
            $key.MachineContext = 1;
            $key.ExportPolicy = 0;
            $key.Create();

            # Subject Name
            $name = New-Object -com 'X509Enrollment.CX500DistinguishedName.1';
            $name.Encode("CN=$($env:COMPUTERNAME)", 0);

            # Certificate Request
            $cert = New-Object -Com 'X509Enrollment.CX509CertificateRequestCertificate.1';
            $cert.InitializeFromPrivateKey(2, $key, [string]::Empty);
            $cert.Subject = $name;
            $cert.Issuer = $cert.Subject;
            $cert.NotBefore = [datetime]::Now;
            $cert.NotAfter = $validUntil;
            for ($i = 0; $i -lt $extsToAdd.Count; $i++) {
                $ext = $extsToAdd[$i];
                $cert.X509Extensions.Add($ext);
            }
            $sigId = New-Object -com 'X509Enrollment.CObjectId.1';
            $hash = [System.Security.Cryptography.Oid]::FromFriendlyName($algorithm, [System.Security.Cryptography.OidGroup]::HashAlgorithm);
            $sigId.InitializeFromValue($hash.Value);
            $cert.SignatureInformation.HashAlgorithm = $sigId;
            $cert.Encode();

            # Complete the Request to Create!
            $enroll = New-Object -com 'X509Enrollment.CX509Enrollment.1';
            $enroll.CertificateFriendlyName = "$env:COMPUTERNAME RDP";
            $enroll.InitializeFromRequest($cert);

            $endCert = $enroll.CreateRequest(1);
            $enroll.InstallResponse(2, $endCert, 1, [string]::Empty);

            [byte[]]$certBytes = [System.Convert]::FromBase64String($endCert);

            # Now use it as the RDP certificate
            $rdpCert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certBytes);
            $inst = Get-CimInstance -Namespace 'root\cimv2\TerminalServices' -ClassName "Win32_TSGeneralSetting" -Filter 'TerminalName = "RDP-Tcp"';
            $inst | Set-CimInstance -Property @{ SSLCertificateSHA1Hash = $rdpCert.Thumbprint };

            return $(New-Object PSObject -Property @{
                NewCertificate = $rdpCert
            });
        }
        if ($PassThru) {
            Write-Output $result -NoEnumerate;
        }
    }
}
