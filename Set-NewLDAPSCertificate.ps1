# This script is used to install an LDAPS certificate in the NTDS Personal and AD LDS service name stores to update the LDAPS certificate 
Write-Output "[*] Importing new PFX LDAPS Certificate into store"
# https://github.com/tobor88/PowerShell/blob/master/Hide-PowerShellScriptPassword.ps1
$KeyPassword = "PFX key password" # I have a script at the above link you can use to encrypt this value so it does not show in clear text
$SecurePassword = ConvertTo-SecureString -String $KeyPassword -Force –AsPlainText
$CertPath = Read-Host -Prompt "Enter the file path of the LDAPS PFX Certificate"
Import-PfxCertificate -FilePath $CertPath -CertStoreLocation "Cert:\LocalMachine\My" -Confirm:$False -Password $SecurePassword -Exportable


Write-Output "[*] Obtaining LDAP over SSL certificate by Template Name from the local machine certificate store"
$LDAPSTemplateName = "LDAP over SSL"
$LDAPSCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript { $_.Extensions | Where-Object -FilterScript { ($_.Oid.FriendlyName -eq "Certificate Template Information") -and ($_.Format(0) -Match $LDAPSTemplateName) }}

Write-Output "[*] Defining the names of the LDAP over SSL services on the domain controllers"
# The NTDS service is the default LDAP service. If you installed AD LDS the name you defined will be whatever custom value you set
$ServiceNames = "NTDS","LDAPS" 

Write-Output "[*] Telling LDAPS services to use the new LDAPS Certificate"
ForEach ($ServiceName in $ServiceNames) {

    Write-Output "[*] Moving PFX certificate into the NTDS\Personal Certificate Store "
    Move-Item -Path "HKLM:\SOFTWARE\Microsoft\SystemCertificates\MY\Certificates\$($LDAPSCert.Thumbprint)" -Destination "HKLM:\SOFTWARE\Microsoft\Cryptography\Services\$ServiceName\SystemCertificates\MY\Certificates\"

}  # End ForEach

Write-Output "[*] Restarting the LDAPS services: `n`t$ServiceNames"
Restart-Service -Name $ServiceNames -Force
