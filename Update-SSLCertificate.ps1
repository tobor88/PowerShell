<#
.SYNOPSIS
This cmdlet has the following requirements
 - OpenSSL : This cmdlet requires openssl to be saved in one of the $env:PATH locations. OpenSSL is used to extract certificates from the PFX file. PFX file needs to be password protected
 - PFX File : This cmdlet requires a PFX file to be saved somewhere locally on the machine this cmdlet is being run from
 - WinRM : WinRM needs to be enabled in the environment in order to execute the needed commands on remote computers
 - LetsEncrypt : IMPORTANT: I assume this is being used with a wildcard LetsEncrypt certificate. If you are using a different 3rd party provider you will need to modify the Select-Object -Skip <Value> to fix your requirements which is used to convert OpenSSL extracted certificates into useful certificates
This cmdlet works by extracting the public certificate, private key certificate, and CA chain certificates from a PFX file using the password you provide and PFX file you define
This will also restart the service(s) if you define the -Service parameter.
This will use WinRM over HTTPS to connect with remote computers if you use the -UseSSL parameter


.DESCRIPTION
Replace the SSL certificate on a remote IIS server hosting a website or another Windows Server hosting a website that requires the replacing of certificate files. Some examples of this case would be PRTG Network Monitor, Gitea, Kibana, Elasticsearch, or Nessus.


.PARAMETER CertPath
.PARAMETER CertDestination
.PARAMETER KeyPath
.PARAMETER KeyDestination
.PARAMETER CAPath
.PARAMETER CADestination
.PARAMETER PfxCertificate
.PARAMETER KeyPassword
.PARAMETER Service
.PARAMETER SiteName
.PARAMETER Computer
.PARAMETER UseSSL
.PARAMETER Credential


.EXAMPLE
Update-SSLCertificate -CertPath $CertificateFile -KeyPath $PrivateKeyFile -CertDestination "C:\Program Files (x86)\PRTG Network Monitor\cert\prtg.crt" -KeyDestination "C:\Program Files (x86)\PRTG Network Monitor\cert\prtg.key" -CAPath $CAChainFile -CADestination "C:\Program Files (x86)\PRTG Network Monitor\cert\root.pem" -PfxCertificate "C:\ProgramData\Certify\assets\_.domain.com\20211234certificate.pfx" -KeyPassword 'Str0ngK3yP@ssw0rd!' -Service "PRTGCoreService","PRTGProbeService" -ComputerName "prtg.domain.com" -UseSSL -Credential (Get-Credential)
# This example replaces the public certiticate, private key certificate, and CA chain certificate files on a PRTG server. It restarts the two PRTG services and saves a copy of the replaced certificates as .old files


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://osbornepro.com
https://writeups.osbornepro.com
https://btpssecpack.osbornepro.com
https://github.com/tobor88
https://gitlab.com/tobor88
https://www.powershellgallery.com/profiles/tobor
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges
https://www.hackthebox.eu/profile/52286
#>
Function Update-SSLCertificate {
    [CmdletBinding(DefaultParameterSetName="File")]
        param(
            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Set the network share path of the directory containing your certificate `n[E] EXAMPLE: \\filesserver.domain.com\Certificates\cert.pem")] # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Set an absolute path to save the extracted PFX certificate `n[E] EXAMPLE: \\filesserver.domain.com\Certificates\cert.pem")] # End Parameter
            [String]$CertPath,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Set the absolute path of the directory containing your certificates key `n[E] EXAMPLE: \\filesserver.domain.com\Certificates\key.pem")] # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Set an absolute path to save your extracted certificates key `n[E] EXAMPLE: \\filesserver.domain.com\Certificates\key.pem")] # End Parameter
            [String]$KeyPath,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Set the aboslute path to save your certificate file `n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\servercert.pem")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Set the aboslute path to save your certificate file `n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\servercert.pem")]  # End Parameter
            [String]$CertDestination,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$True,
                HelpMessage="[H] Set the aboslute path to save your certificates Key file `n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\serverkey.pem")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$True,
                HelpMessage="[H] Set the aboslute path to save your certificates Key file `n[E] EXAMPLE: C:\ProgramData\Tenable\Nessus\nessus\CA\serverkey.pem")]  # End Parameter
            [String]$KeyDestination,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False)]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$False)]  # End Parameter
            [String]$CAPath,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False)]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$False)]  # End Parameter
            [String]$CADestination,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False,
                HelpMessage="[H] `n[E] EXAMPLE: C:\ProgramData\Certify\assets\_.yourdomain.com\wildcard.pfx")]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$False,
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
            [String]$KeyPassword,

            [Parameter(
                ParameterSetName="IIS",
                Mandatory=$False)]  # End Parameter
            [Parameter(
                ParameterSetName="File",
                Mandatory=$False)]  # End Parameter
            [String[]]$Service,

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
            [System.Management.Automation.CredentialAttribute()]$Credential

        )  # End param

BEGIN {

    Write-Warning "OPENSSL REQUIRED : This script requires openssl.exe to be placed into one of the `$env:PATH directories to work"
    Write-Output "`tDOWNLOAD: OpenSSL does not host official binaries however one can obtained from https://sourceforge.net/projects/openssl-for-windows/files/latest/download"
    Write-Output "`tDOWNLOAD: Certify Community Edition from https://certifytheweb.com/"

    $Bool = $False
    If ($UseSSL.IsPresent) {

        $Bool = $True

    }  # End If

    $Source = "$env:COMPUTERNAME.$env:USERDNSDOMAIN".ToLower()
    $Cert = $CertPath.Split("\")[-1]
    $Key = $KeyPath.Split("\")[-1]
    $Root = $KeyPath.Replace("\$Key","")
    $Compare = $CertPath.Replace("\$Cert","")
    $SecurePassword = ConvertTo-SecureString -String $KeyPassword -Force –AsPlainText

    If ($Root -ne $Compare) {

        Throw "[x] Cretificate file and Key file required to be saved in same location"

    }  # End If

    If ($Null -eq $PfxCertificate) {

        Write-Output "[*] Obtaining latest wildcard certificate file from the default Certify Community Edition's save location"
        $CertifySavePath = Get-ChildItem -Path "C:\ProgramData\Certify\assets\_.*.*\" | Select-Object -ExpandProperty "FullName"
        $PfxCertificate = Get-ChildItem -Path $CertifySavePath -Filter "*.pfx" | Where-Object -Property "CreationTime" -like "$($(Get-Date -Format MM/dd/yyyy))*" | Select-Object -First 1 -ExpandProperty "FullName"
        $FileName = $PfxCertificate.Split("\")[-1]

    }  # End If

    Write-Output "[*] Extracting Private Key using openssl"
    openssl pkcs12 -in $PfxCertificate -nocerts -nodes -out "$CertifySavePath\key.txt" -passin pass:"$KeyPassword"
    Get-Content -Path "$CertifySavePath\key.txt" | Select-Object -Skip 4 | Out-File -FilePath "$KeyPath" -Encoding utf8

    Write-Output "[*] Extracting Public Cert using openssl"
    openssl pkcs12 -in $LocalWildcardFile.FullName -clcerts -nokeys -out "$CertifySavePath\cert.txt" -passin pass:"$KeyPassword"
    Get-Content -Path "$CertifySavePath\cert.txt" | Select-Object -Skip 5 | Out-File -FilePath "$CertPath" -Encoding utf8

    Write-Output "[*] Extracting CA Chain Certificates using openssl"
    openssl pkcs12 -in $LocalWildcardFile.FullName -cacerts -nokeys -chain -out "$CertifySavePath\ca.txt" -passin pass:"$KeyPassword"
    Get-Content -Path "$CertifySavePath\ca.txt" | Select-Object -Skip 3 | Out-File -FilePath "$CAPath" -Encoding utf8


}  # End BEGIN
PROCESS {

    Switch ($PsCmdlet.ParameterSetName) {

        'IIS' {

            ForEach ($Cn in $ComputerName) {

                If (!(Test-WSMan -ComputerName $Cn -UseSSL:$Bool)) {

                    Write-Output "[x] Unable to reach $Cn using WinRM. Ensure you used a FQDN and that the server is reachable on the network with WinRM enabled"

                }  # End If
                Else {

                    Invoke-Command -HideComputerName $Cn -UseSSL:$Bool -ArgumentList $SiteName,$PfxCertificate,$SecurePassword,$Credential,$Source -ScriptBlock {

                        Import-Module -Name WebAdministration -Global

                        $SiteName = $Args[0]
                        $PfxCertificate = $Args[1]
                        $SecurePassword = $Args[2]
                        $Credential = $Args[3]
                        $Source = $Args[4]

                        $PfxFile = $PfxCertificate.Split("\")[-1]
                        $PfxDir = $PfxCertificate.Replace("\$PfxFile", "")
                        $PfxNet = $$PfxDir.Replace("C:\","$Source\C$\")

                        Write-Output "[*] Mapping a temporary drive using the letter T"
                        New-PsDrive -Name T -PSProvider FileSystem -Root $PfxNet -Scope Global -Credential $Credential

                        Write-Output "[*] Importing PFX certificate into local machine store"
                        Import-PfxCertificate -FilePath "T:\$PfxFile" -CertStoreLocation "Cert:\LocalMachine\My" -Confirm:$False -Password $SecurePassword -Exportable

                        Write-Output "[*] Obtaining thumbprint of certificate with the subject name CN=*.$($($env:USERDNSDOMAIN.ToLower())) that was created today"
                        $Thumbprint = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { ($_.Subject -eq "CN=*.$($($env:USERDNSDOMAIN.ToLower()))") -and ($_.NotBefore -like "$($(Get-Date -Format MM/dd/yyyy))*") } | Select-Object -ExpandProperty Thumbprint

                        ForEach ($S in $SiteName) {

                            Write-Output "[*] Defining new wildcard certificate on $env:COMPUTERNAME for the site $Site"
                            $Binding = Get-WebBinding -Name $Site -Protocol "https"
                            $Binding.AddSslCertificate($Thumbprint, "my")

                        }  # End ForEach

                        Write-Output "[*] Restarting the IIS service"
                        iisreset /RESTART

                    }  # End Invoke-Command

                }  # End Else

            }  # End ForEach

        }  # End IIS

        'File' {

            If (!(Test-WSMan -ComputerName $ComputerName -UseSSL:$Bool)) {

                Write-Output "[x] Unable to reach $ComputerName using WinRM. Ensure you used a FQDN and that the server is reachable on the network with WinRM enabled"

            }  # End If
            Else {

                $PfxContents = [Convert]::ToBase64String((Get-Content -Path $PfxCertificate -Encoding Byte))
                $CertContents = Get-Content -Path $CertPath | Out-String
                $KeyContents = Get-Content -Path $KeyPath | Out-String
                $CAContents = Get-Content -Path $CAPath | Out-String

                Invoke-Command -HideComputerName $ComputerName -UseSSL:$Bool -Authentication Default -ArgumentList $KeyPath,$CertPath,$KeyDestination,$CertDestination,$Service,$CAPath,$CADestination,$CertContents,$KeyContents,$CAContents,$PfxContents,$PfxCertificate,$KeyPassword,$Source -ScriptBlock {

                    $KeyPath = $Args[0]
                    $CertPath = $Args[1]
                    $KeyDestination = $Args[2]
                    $CertDestination = $Args[3]
                    $Service = $Args[4]
                    $CAPath = $Args[5]
                    $CADestination = $Args[6]
                    $CertContents = $Args[7]
                    $KeyContents = $Args[8]
                    $CAContents = $Args[9]
                    $PfxContents = $Args[10]
                    $PfxCertificate = $Args[11]
                    $KeyPassword = $Args[12]
                    $Source = $Args[13]

                    $PfxFile = $PfxCertificate.Split("\")[-1]
                    $PfxDir = $PfxCertificate.Replace("\$PfxFile", "")
                    $PfxNet = $$PfxDir.Replace("C:\","$Source\C$\")

                    $Cert = $CertPath.Split("\")[-1]
                    $Key = $KeyPath.Split("\")[-1]

                    $KeyDestPath = $KeyDestination.Replace("\$(($KeyDestination.Split("\")[-1]))","")
                    $CertDestPath = $CertDestination.Replace("\$(($CertDestination.Split("\")[-1]))","")

                    $KeySourcePath = $KeyPath.Replace("\$Key","")
                    $CertSourcePath = $CertPath.Replace("\$Cert","")

                    Write-Output "[*] Renaming current PEM files to OLD files"
                    Rename-Item -Path $KeyDestination -NewName "$KeyDestination.old" -Force
                    Rename-Item -Path "$CertDestination" -NewName "$CertDestination.old" -Force

                    Write-Output "[*] Moving over new certificate files"
                    New-Item -Path $CertDestination.Replace("C:\","\\$env:COMPUTERNAME\C$\") -ItemType File -Value $CertContents -Force
                    New-Item -Path $KeyDestination.Replace("C:\","\\$env:COMPUTERNAME\C$\") -ItemType File -Value $KeyContents -Force

                    Write-Output "[*] Importing the PFX certificate"
                    $SecurePassword = ConvertTo-SecureString -String $KeyPassword -Force –AsPlainText
                    $Bytes = [Convert]::FromBase64String($PfxContents))
                    [System.IO.File]::WriteAllBytes("C:\Users\Public\Documents\deletethiscert.pfx", $Bytes)
                    Import-PfxCertificate -FilePath $PfxNet -CertStoreLocation "Cert:\LocalMachine\My" -Confirm:$False -Password $SecurePassword -Exportable
                    Remove-Item -Path "C:\Users\Public\Documents\deletethiscert.pfx" -Force -ErrorAction SilentlyContinue | Out-Null

                    If ($CAPath.Length -gt 1) {

                        $CA = $CAPath.Split("\")[-1]
                        $CASourcePath = $CAPath.Replace("\$CA","")
                        $CADestPath = $CADestination.Replace("\$(($CADestination.Split("\")[-1]))","")

                        Rename-Item -Path $CADestination -NewName "$CADestination.old" -Force
                        New-Item -Path $CADestination.Replace("C:\","\\$env:COMPUTERNAME\C$\") -ItemType File -Value $CAContents -Force

                    }  # End If

                    If (($Null -ne $Service) -and (Get-Service -Name $Service -ErrorAction SilentlyContinue) -ne $Null) {

                        Write-Verbose "Restarting the service $Service"
                        Restart-Service -Name $Service -Force

                    }  # End If

                }  # End Invoke-Command

            }  # End Else

        }  # End Remote

    }  # End Switch

}  # End PROCESS

}  # End Update-SSLCertificate
