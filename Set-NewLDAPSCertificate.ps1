#Requires -Version 3.0
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator
<#
.SYNOPSIS
This script is used to install the LDAP over SSL certificate template you have on your Domain Controller


.DESCRIPTION
Retrieve the current certificates from the Local Machine certificate store using the template name you define
Retrieve any expiring soon or expired certificates that use that template name in the local computer certificate store (certlm.msc)
If expiring certificate is found it gets renewed with the same key and obtains the certificate info after renewal
If a new certificate is issued, the old one is removed and the new one is assigned to the NTDS service
A registry path is added using the current certificate thumbprint which assigns it to the NTDS service
The NTDS service is restarted to apply changes


.PARAMETER LdapServiceName
Define the name of the LDAP service if it is not the default NTDS

.PARAMETER CertificateTemplateName
Define the name of your LDAPS certificate template. NO SPACES ARE IN THIS NAME

.PARAMETER ExpiringInDays
Define how many days until an LDAPS certificate is expiring that you renew it


.EXAMPLE
PS> .\Set-CurrentCertificate -LdapServiceName NTDS -CertificateTemplateName LDAPoverSSL -ExpiringInDays 30 -Verbose
# This example uses the certificate template LDAPoverSSL that has previously been issued to your domain controller and assigns it to the NTDS service.
# This assignment to the NTDS service is also completed if the current LDAPS certificate is expiring in less than 30 days
# I suggest using the -Verbose parameter if you are running this on your own to see what is happening.

.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://osbornepro.com


.INPUTS
System.String
System.SecureString


.OUTPUTS
System.String
#>
[OutputType([System.String])]
[CmdletBinding(
    SupportsShouldProcess=$True,
    ConfirmImpact="Medium"
)]  # End CmdletBinding
    param(
        [Parameter(
            Mandatory=$False
        )]  # End Parameter
        [String]$LdapServiceName = "NTDS",

        [Parameter(
            Mandatory=$True,
            HelpMessage="[?] What is the name of your LDAPS certificate template on your Windows Certificate Authority? This is the name without any spaces`n[EXAMPLE] LDAPS`n[INPUT] "
        )]  # End Parameter
        [String]$CertificateTemplateName,

        [Parameter(
            Mandatory=$False
        )]  # End Parameter
        [Int32]$ExpiringInDays = 30
    )  # End param

Try {

    $VerbosePreference = 'Continue'
    $CurrentDate = Get-Date
    $LogDir = "C:\Windows\Logs\Tasks"
    $LogFile = "$($LogDir)\PS_RenewLdapCertificateTask.log"
    New-Item -Path $LogDir -ItemType Directory -Force -WhatIf:$False -Verbose:$False -ErrorAction SilentlyContinue | Out-Null
    Start-Transcript -Path $LogFile -Append -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -WhatIf:$False | Out-Null
    
    Write-Verbose -Message "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Obtaining LDAP over SSL certificate using Template Name $CertificateTemplateName in your local Computer Certificate store (certlm.msc)"
    $CurrentCerts = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript {
        $_.Extensions | Where-Object -FilterScript { ($_.Oid.FriendlyName -eq "Certificate Template Information") -and ($_.Format(0) -Match $CertificateTemplateName) }
    }  # End Where-Object

    Write-Verbose -Message "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Obtaining any expiring or expired LDAP over SSL certificate using Template Name $CertificateTemplateName in your local Computer Certificate store (certlm.msc)"
    $ExpiringCerts = $CurrentCerts | Where-Object -FilterScript {
        $_.NotAfter -le $CurrentDate.AddDays($ExpiringInDays)
    }  # End Where-Object

    If ($ExpiringCerts) {

        Write-Verbose -Message "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') There is a current LDAPS certificate that is expiring"
        Start-Process -WorkingDirectory "C:\Windows\System32" -FilePath certreq.exe -ArgumentList @('-Enroll', '-machine', '-q', '-cert', $ExpiringCerts.SerialNumber, 'Renew', 'ReuseKeys') -Wait

        Write-Verbose -Message "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Pulling the newly issued certificate's information"
        $CurrentCerts = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript {
            $_.Extensions | Where-Object -FilterScript { ($_.Oid.FriendlyName -eq "Certificate Template Information") -and ($_.Format(0) -Match $CertificateTemplateName) }
        }  # End Where-Object

        $NewCert = $CurrentCerts | Where-Object -FilterScript { $_.Thumbprint -ne $ExpiringCerts.Thumbprint }
        If ($NewCert) {

            Write-Verbose -Message "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Deleting the old certificate from the LocalMachine Certificate store"
            $ExpiringCerts | ForEach-Object -Process { 
                Remove-Item -Path "Cert:\LocalMachine\My\$($_.Thumbprint)"
            }  # End ForEach-Object

        } Else {

            Write-Output -InputObject "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') LDAPS Certificate does not need to be renewed"

        }  # End If Else

    }  # End If

    $RegPath = "HKLM:\SOFTWARE\Microsoft\SystemCertificates\MY\Certificates\$($CurrentCerts.Thumbprint)"
    If (($ExpiringCerts) -and (Test-Path -Path $RegPath)) {

        Write-Verbose -Message "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Moving PFX certificate into the NTDS\Personal Certificate Store"
        Copy-Item -Path $RegPath -Destination "HKLM:\SOFTWARE\Microsoft\Cryptography\Services\$($LdapServiceName)\SystemCertificates\MY\Certificates\" | Out-Null

        Write-Verbose -Message "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Restarting the $($LdapServiceName) service"
        Restart-Service -Name $LdapServiceName -Force | Out-Null

    } ElseIf ($Null -eq $ExpiringCerts) {
    
        Return "RESULT: $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') LDAPS Certificate does not need to be renewed"

    } Else {

        Throw "$(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Expected registry path defining LDAPS certificate does not exist: $($RegPath)"

    }  # End If Else

    Return "RESULT: $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Successfully assigned the LDAPS certificate to $($LdapServiceName)"

} Finally {

    $VerbosePreference = 'SilentlyContinue'
    Stop-Transcript -Verbose:$False -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null

}  # End Try Finally
