# This script is used to install an LDAPS certificate in the NTDS Personal and AD LDS service name stores to update the LDAPS certificate 

# https://github.com/tobor88/PowerShell/blob/master/Hide-PowerShellScriptPassword.ps1
$KeyPassword = "LDAPS-S3cr3t-Pa55w0rd" # I have a script at the above link you can use to encrypt this value so it does not show in clear text
$SecurePassword = ConvertTo-SecureString -String $KeyPassword -Force –AsPlainText
$CertPath = "$env:USERPROFILE\Downloads\LDAPS.pfx"
$LDAPSTemplateName = "LDAP over SSL"
$ServiceNames = "NTDS",((Get-CimInstance -ClassName Win32_Service -Filter 'Name LIKE "%ADAM%"').Name)
# NTDS is the default LDAP service. 
# AD LDS if installed will have a custom service name you set 
# I try to discover that automatically for you using a search for a process with ADAM in the name


Write-Output "[*] Obtaining LDAP over SSL certificate by Template Name from the local machine certificate store"
$LDAPSCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript { $_.Extensions | Where-Object -FilterScript { ($_.Oid.FriendlyName -eq "Certificate Template Information") -and ($_.Format(0) -Match $LDAPSTemplateName) }}

# The commented area below is just in case we need to export or import a PFX certificate into the localmachine store
#
#Write-Output "[*] Exporting LDAPS certificate from LocalMachine store"
#Export-PfxCertificate -FilePath $CertPath -Password $SecurePassword
#
#Write-Output "[*] Importing new PFX LDAPS Certificate into store"
#Import-PfxCertificate -FilePath $CertPath -CertStoreLocation "Cert:\LocalMachine\My" -Confirm:$False -Password $SecurePassword -Exportable


Write-Output "[*] Telling LDAPS services to use the new LDAPS Certificate"
ForEach ($ServiceName in $ServiceNames) {

    If ($ServiceName.Length -gt 0) {

        If (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\SystemCertificates\MY\Certificates\$($LDAPSCert.Thumbprint)") {
        
            Write-Output "[*] Moving PFX certificate into the NTDS\Personal Certificate Store "
            Move-Item -Path "HKLM:\SOFTWARE\Microsoft\SystemCertificates\MY\Certificates\$($LDAPSCert.Thumbprint)" -Destination "HKLM:\SOFTWARE\Microsoft\Cryptography\Services\$ServiceName\SystemCertificates\MY\Certificates\"

            Write-Output "[*] Restarting the $ServiceName service"
            Restart-Service -Name $ServiceName -Force -ErrorAction Inquire

        }  # End If
        Else {

            Write-Warning "Expected registry path defining LDAPS certificate does not exist"

        }  # End Else

    }  # End If

}  # End ForEach
