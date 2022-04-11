<#
.SYNOPSIS
This cmdlet has the following requirements
 - PFX file needs to be password protected
 - PFX file needs to be saved somewhere locally on the machine this cmdlet is being run from
 - WinRM needs to be enabled in the environment in order to execute the needed commands on remote computers (Test-WsMan -ComputerName $ComputerName)
This cmdlet works by extracting the public certificate, private key certificate, and CA chain certificates from a PFX file using the password you provide and PFX file you define
This will also restart the service(s) if you define the -Service parameter.
This will use WinRM over HTTPS to connect with remote computers if you use the -UseSSL parameter


.DESCRIPTION
Replace the SSL certificate on a remote IIS server hosting a website or another Windows Server hosting a website that requires the replacing of certificate files. Some examples of this case would be PRTG Network Monitor, Gitea, Kibana, Elasticsearch, or Nessus.


.PARAMETER CertPath
Enter a path to save your public certificate file too

.PARAMETER CertDestination
Enter the destination path to save your certificates public cert on a remote device

.PARAMETER KeyPath
Enter a path to save your certificate key file

.PARAMETER KeyDestination
Enter the destination path to save your certificate key file for a remote service

.PARAMETER CAPath
Enter the path to the Root CA file that will get trusted on a remote computer

.PARAMETER CADestination
Enter the destination path to save a Root CA file on a remote computer in accordance with that services documentation

.PARAMETER PfxCertificate
Define the location of the PFX certificate file

.PARAMETER KeyPassword
Enter the password to unlock the PFX file

.PARAMETER RemoteService
Enter the name of the service running on a remote machine that needs to be restarted after updating the SSL certificate for it 

.PARAMETER SiteName
Enter the name of an IIS site to update the SSL certificate on

.PARAMETER Computer
Define a remote computer to update the certificate on

.PARAMETER UseSSL
Use WinRM over SSL for remote connections

.PARAMETER Credential
Enter your admin credentials which are used to map network locations and execute commands on remote machines


.EXAMPLE
Update-SSLCertificate -CertPath C:\Temp\cert.pem -KeyPath C:\Temp\key.pem -CertDestination "C:\Program Files (x86)\PRTG Network Monitor\cert\prtg.crt" -KeyDestination "C:\Program Files (x86)\PRTG Network Monitor\cert\prtg.key" -CAPath $CAChainFile -CADestination "C:\Program Files (x86)\PRTG Network Monitor\cert\root.pem" -PfxCertificate "C:\Temp\ssl-cert.pfx" -KeyPassword (ConvertTo-SecureString -AsPlainTest -Force -String 'Str0ngK3yP@ssw0rd!') -Service "PRTGCoreService","PRTGProbeService" -ComputerName "prtg.domain.com" -UseSSL -Credential (Get-Credential)
# This example replaces the public certiticate, private key certificate, and CA chain certificate files on a PRTG server. It restarts the two PRTG services and saves a copy of the replaced certificates as .old files


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://www.vinebrooktechnology.com/
#>
Function Update-SSLCertificate {
    [CmdletBinding(DefaultParameterSetName="File")]
        param(
            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Set an absolute path to save the extracted public certificate `n[E] EXAMPLE: \\filesserver.domain.com\Certificates\cert.pem")] # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Set an absolute path to save the extracted public certificate `n[E] EXAMPLE: \\filesserver.domain.com\Certificates\cert.pem")] # End Parameter
            [String]$CertPath,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Set an absolute path to save your extracted certificates key `n[E] EXAMPLE: \\filesserver.domain.com\Certificates\key.pem")] # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Set an absolute path to save your extracted certificates key `n[E] EXAMPLE: \\filesserver.domain.com\Certificates\key.pem")] # End Parameter
            [String]$KeyPath,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Set the aboslute path to save your certificate file on the remote machine running a service with HTTPS`n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\servercert.pem")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Set the aboslute path to save your certificate file on the remote machine running a service with HTTPS`n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\servercert.pem")]  # End Parameter
            [String]$CertDestination,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Set the aboslute path to save your certificates Key file on the remote machine running a service with HTTPS `n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\serverkey.pem")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Set the aboslute path to save your certificates Key file on the remote machine running a service with HTTPS`n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\serverkey.pem")]  # End Parameter
            [String]$KeyDestination,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False,
                HelpMessage="[H] Set the aboslute path for the Root CA certificate file`n[E] EXAMPLE: C:\Temp\digicertCA.pem")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$False,
                HelpMessage="[H] Set the aboslute path for the Root CA certificate file`n[E] EXAMPLE: C:\Temp\digicertCA.pem")]  # End Parameter
            [String]$CAPath,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False,
                HelpMessage="[H] Set the aboslute path to save your certificates Root CA file on the remote machine running a service with HTTPS`n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\serverkey.pem")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$False,
                HelpMessage="[H] Set the aboslute path to save your certificates Root CA file on the remote machine running a service with HTTPS`n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\serverkey.pem")]  # End Parameter
            [String]$CADestination,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] `n[E] EXAMPLE: C:\ProgramData\Certify\assets\_.yourdomain.com\wildcard.pfx")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] `n[E] EXAMPLE: C:\ProgramData\Certify\assets\_.yourdomain.com\wildcard.pfx")]  # End Parameter
            [ValidateScript({((Test-Path -Path $_) -and ($_ -like "*.pfx"))})]
            [String]$PfxCertificate,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Enter the password being used to protect the PFX file's private key `n[E] EXAMPLE: Str0ngk#3yP@ssw0rd!")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Enter the password being used to protect the PFX file's private key `n[E] EXAMPLE: Str0ngk#3yP@ssw0rd!")]  # End Parameter
            [SecureString]$KeyPassword,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False)]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$False)]  # End Parameter
            [String[]]$RemoteService,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage = "[H] Define the site name of the IIS Site to update the certificate on. EXAMPLE: Default Web Site")]  # End Parameter
            [String]$SiteName,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="[H] Define the remote host(s) to update the certificate on `n[E] EXAMPLE: desktop01.domain.com, server.domain.com")]  # End Parameter
           [Parameter(
                ParameterSetName="File",
                Mandatory=$False,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="[H] Define the remote host(s) to update the certificate on `n[E] EXAMPLE: desktop01.domain.com, server.domain.com")]  # End Parameter
            [String[]]$ComputerName,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False)]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$False)]  # End Parameter
            [switch][bool]$UseSSL,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True)]  # End Parameter
            [Parameter(
                ParameterSetNAme="File",
                Mandatory=$True)]  # End Parameter
            [System.Management.Automation.CredentialAttribute()][SecureString]$Credential
        )  # End param

BEGIN {

    $Bool = $False
    If ($UseSSL.IsPresent) {

        $Bool = $True

    }  # End If

    $Source = "$env:COMPUTERNAME.$env:USERDNSDOMAIN".ToLower()
    $CertFileName = $CertPath.Split("\")[-1]
    $KeyFileName = $KeyPath.Split("\")[-1]
    $Root = $KeyPath.Replace("\$KeyFileName","")
    $Compare = $CertPath.Replace("\$CertFileName","")

    If ($Root -ne $Compare) {

        Throw "[x] Certificate file and Key file are required to exist in same location"

    }  # End If

    Write-Output "[*] Extracting Certificate and Key into single file"
    Convert-PfxToPem -InputFile $PfxCertificate -Outputfile ("$WildcardPath" + "key.pem") -Password $SecurePassword
    
    Write-Output "[*] Separating certificate and key into separate files"
    $FileContents = Get-Content -Path ("$WildcardPath" + "key.pem") -Raw
    $FileContents -Match "(?ms)(\s*((?<privatekey>-----BEGIN PRIVATE KEY-----.*?-----END PRIVATE KEY-----)|(?<certificate>-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----))\s*){2}"
    $Matches["privatekey"] | Out-File -FilePath "$KeyPath" -Force
    $Matches["certificate"] | Out-File -FilePath "$CertPath" -Force


}  # End BEGIN
PROCESS {

    Switch ($PsCmdlet.ParameterSetName) {

        'IIS' {

            ForEach ($Cn in $ComputerName) {

                If (!(Test-WSMan -ComputerName $Cn -UseSSL:$Bool)) {

                    Write-Output "[x] Unable to reach $Cn using WinRM. Ensure you used a FQDN and that the server is reachable on the network with WinRM enabled"

                }  Else {

                    Invoke-Command -HideComputerName $Cn -UseSSL:$Bool -ArgumentList $SiteName,$PfxCertificate,$KeyPassword,$Credential,$Source -ScriptBlock {

                        Import-Module -Name WebAdministration -Global

                        $SiteName = $Args[0]
                        $PfxCertificate = $Args[1]
                        $KeyPassword = $Args[2]
                        $Credential = $Args[3]
                        $Source = $Args[4]

                        $PfxFile = $PfxCertificate.Split("\")[-1]
                        $PfxDir = $PfxCertificate.Replace("\$PfxFile", "")
                        $PfxNet = $PfxDir.Replace("C:\","$Source\C$\")

                        Write-Output "[*] Mapping a temporary drive using the letter T"
                        New-PsDrive -Name T -PSProvider FileSystem -Root $PfxNet -Scope Global -Credential $Credential

                        Write-Output "[*] Importing PFX certificate into local machine store"
                        Import-PfxCertificate -FilePath "T:\$PfxFile" -CertStoreLocation "Cert:\LocalMachine\My" -Confirm:$False -Password $KeyPassword -Exportable

                        Write-Output "[*] Obtaining thumbprint of certificate"
                        $Thumbprint = (Get-PfxCertificate -Filepath "T:\$PfxFile").Thumbprint

                        ForEach ($S in $SiteName) {

                            Write-Output "[*] Defining new wildcard certificate on $env:COMPUTERNAME for the site $Site"
                            $Binding = Get-WebBinding -Name $Site -Protocol "https"
                            $Binding.AddSslCertificate($Thumbprint, "my")

                        }  # End ForEach

                        $Answer = Read-Host -Prompt "Would you like to restart the IIS site to apply the new certificate? [y/N]"
                        If ($Answer -like "y*") {
                        
                            Write-Output "[*] Restarting the IIS service"
                            iisreset /RESTART
                        
                        }  # End If
                    
                    }  # End Invoke-Command

                }  # End Else

            }  # End ForEach
        
        }  # End IIS
        'File' {

            If (!(Test-WSMan -ComputerName $ComputerName -UseSSL:$Bool)) {

                Write-Output "[x] Unable to reach $ComputerName using WinRM. Ensure you used a FQDN and that the server is reachable on the network with WinRM enabled"

            } Else {

                $PfxContents = [Convert]::ToBase64String((Get-Content -Path $PfxCertificate -Encoding Byte))
                $CertContents = Get-Content -Path $CertPath | Out-String
                $KeyContents = Get-Content -Path $KeyPath | Out-String
                $CAContents = Get-Content -Path $CAPath | Out-String

                Invoke-Command -HideComputerName $ComputerName -UseSSL:$Bool -Authentication Default -ArgumentList $KeyDestination,$CertDestination,$RemoteService,$CAPath,$CADestination,$CertContents,$KeyContents,$CAContents,$PfxContents,$PfxCertificate,$KeyPassword,$Source -ScriptBlock {

                    $KeyDestination = $Args[0]
                    $CertDestination = $Args[1]
                    $RemoteService = $Args[2]
                    $CAPath = $Args[3]
                    $CADestination = $Args[4]
                    $CertContents = $Args[5]
                    $KeyContents = $Args[6]
                    $CAContents = $Args[7]
                    $PfxContents = $Args[8]
                    $PfxCertificate = $Args[9]
                    $KeyPassword = $Args[10]
                    $Source = $Args[11]

                    $PfxFile = $PfxCertificate.Split("\")[-1]
                    $PfxDir = $PfxCertificate.Replace("\$PfxFile", "")
                    $PfxNet = $PfxDir.Replace("C:\","$Source\C$\")

                    Write-Output "[*] Renaming current PEM files to OLD files"
                    Rename-Item -Path $KeyDestination -NewName "$KeyDestination.old" -Force
                    Rename-Item -Path "$CertDestination" -NewName "$CertDestination.old" -Force

                    Write-Output "[*] Moving over new certificate files"
                    New-Item -Path $CertDestination.Replace("C:\","\\$env:COMPUTERNAME\C$\") -ItemType File -Value $CertContents -Force
                    New-Item -Path $KeyDestination.Replace("C:\","\\$env:COMPUTERNAME\C$\") -ItemType File -Value $KeyContents -Force

                    Write-Output "[*] Importing the PFX certificate"

                    $Bytes = [Convert]::FromBase64String($PfxContents)
                    [System.IO.File]::WriteAllBytes("C:\Users\Public\Documents\deletethiscert.pfx", $Bytes)
                    Import-PfxCertificate -FilePath $PfxNet -CertStoreLocation "Cert:\LocalMachine\My" -Confirm:$False -Password $KeyPassword -Exportable
                    Remove-Item -Path "C:\Users\Public\Documents\deletethiscert.pfx" -Force -ErrorAction SilentlyContinue | Out-Null

                    If ($CAPath.Length -gt 1) {

                        Rename-Item -Path $CADestination -NewName "$CADestination.old" -Force
                        New-Item -Path $CADestination.Replace("C:\","\\$env:COMPUTERNAME\C$\") -ItemType File -Value $CAContents -Force

                    }  # End If

                    If (($Null -ne $RemoteService) -and ($Null -ne (Get-Service -Name $RemoteService -ErrorAction SilentlyContinue))) {

                        Write-Verbose "Restarting the service $RemoteService"
                        Restart-Service -Name $RemoteService -Force

                    }  # End If

                }  # End Invoke-Command

            }  # End If Else

        }  # End File

    }  # End Switch

}  # End PROCESS
END {

    Write-Output "[*] Completed execution"

}  # End END

}  # End Update-SSLCertificate
