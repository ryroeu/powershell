<#
.SYNOPSIS
    Retrieves self signed cert.
#>

$define = @{
    FilePath = 'C:\Git\PSautomateCert.pfx'
    Password = (ConvertTo-SecureString -AsPlainText -String 'password' -Force)
}
$cert = Get-PfxCertificate @define

$define = @{
    ClientId = 'client-id-from-azure'
    TenantId = 'tenant-id-from-azure'
    Certificate = $cert
}
Connect-Graph @$define