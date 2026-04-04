<#
This example submits a certificate request for the SslWebServer template to the specific URL using the user name and password credentials.
The request will have two DNS names in it.
This is for a certificate in the machine store.
If the request is issued, then the returned certificate is installed in the machine MY store and the certificate in the EnrollmentResult structure is returned with the status Issued.
If the request is made pending, then the request is installed in the machine REQUEST store and the request in the EnrollmentResult structure is returned with the status Pending.
#>
$PSCredential = Get-Credential
Get-Certificate -Template SslWebServer -DnsName www.contoso.com,www.fabrikam.com -Url https://www.contoso.com/Policy/service.svc -Credential $PSCredential -CertStoreLocation cert:\LocalMachine\My