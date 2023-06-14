#Requires -Version 3.0
Function Invoke-WinSCPDownload {
<#
.SYNOPSIS
This cmdlet is used to copy files to an FTP server using WinSCP


.DESCRIPTION
Use WinSCP to copy files to a destination FTP server


.PARAMETER Protocol
Define the protocol to use when connecting to the WinSCP FTP server

.PARAMETER Server
Define the SFTP server hostname, FQDN, or IP Address

.PARAMETER Port
Define the destination port to connect to on the WinSCP FTP server

.PARAMETER LocalPath
Define the location to copy files too

.PARAMETER RemotePath
Define the file path on the SFTP server to download files from

.PARAMETER EnumerateDirectory
Return the list of all files in the destination you specify on the SFTP server

.PARAMETER Credential
Enter credentials to authenticate to the SFTP server

.PARAMETER Username
Enter the username to authenticate to the FTP server with

.PARAMETER Password
Enter the password of the user to authenticate with

.PARAMETER KeyUsername
Enter the username associated with the private key

.PARAMETER SshPrivateKeyPath
Enter the file path to a PPK file containing the private key to authenticate with

.PARAMETER SshPrivateKeyPassPhrase
Define the pass phrase used to protect the private key in the PPK file

.PARAMETER HostKeyPolicy
Define the host key policy for previously unknown host keys

.PARAMETER FTPMode
Define whether to use Active of Passive FTP mode

.PARAMETER FTPEncryption
Define whether to not use encryption or use Implicit or Explicit encryption

.PARAMETER TrustCertificate
Tells your device to trust the FTPS servers SSL certificate

.PARAMETER Timeout
Define the connection timeout to the FTP server

.PARAMETER WinScpDllPath
Define the location of the WinSCP NET Assembly DLL file containing the require .NET Assembly obects


.EXAMPLE
PS> Invoke-WinSCPDownload -Protocol Sftp -Server 127.0.0.1 -Credential (Get-Credential) -LocalPath "C:\Temp" -RemotePath "C:\SFTP\Downloads"
# This example copies the importantfile.txt and otherfile2.txt to the WinSCP destination C:\SFTP\Uploads using passive FTP over SSH (SFTP). There is a 15 second timeout to connect to the destination server and any new host keys are automatically accepted

.EXAMPLE
PS> Invoke-WinSCPDownload -Protocol Sftp -Server 127.0.0.1 -Username admin -Password (ConvertTo-SecureString -String "Password123!" -AsPlainText -Force) -LocalPath "C:\Temp" -RemotePath "C:\SFTP\Downloads" -EnumerateDirectory -FTPMode Passive -Timeout 15 -HostKeyPolicy AcceptNew -WinScpDllPath "C:\ProgramData\WinSCP\WinSCPnet.dll"
# This example copies the importantfile.txt and otherfile2.txt to the WinSCP destination C:\SFTP\Uploads using passive FTP over SSH (SFTP) and lists the contents of the destination directory. There is a 15 second timeout to connect to the destination server and any new host keys are automatically accepted

.EXAMPLE
PS> Invoke-WinSCPDownload -Protocol Ftp -FtpEncryption "Implicit" -Server 127.0.0.1 -KeyUserName admin -SshPrivateKeyPassPhrase "Keypassword123!" -SshPrivateKeyPath "C:\Users\admin\.ssh\id_rsa.ppk" -LocalPath "C:\Temp" -RemotePath "C:\SFTP\Downloads" -HostKeyPolicy Check
# This example copies the importantfile.txt and otherfile2.txt to the WinSCP destination C:\SFTP\Uploads using passive FTP over SSL (FTPS). There is a 15 second timeout to connect to the destination server and any new host keys will prompt for confirmation

.EXAMPLE
PS> Invoke-WinSCPDownload -Protocol Ftp -FtpEncryption "Explicit" -Server 127.0.0.1 -Credential (Get-Credential) -LocalPath "C:\Temp" -RemotePath "C:\SFTP\Downloads" -EnumerateDirectory -FTPMode Active -Timeout 15 -HostKeyPolicy GiveUpSecurityAndAcceptAny
# This example copies the importantfile.txt and otherfile2.txt to the WinSCP destination C:\SFTP\Uploads using passive FTP over SSL (FTPS) and lists the contents of the destination directory. There is a 15 second timeout to connect to the destination server and any ignores host keys


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: info@osbornepro.com


.LINK
https://github.com/tobor88
https://github.com/osbornepro
https://www.powershellgallery.com/profiles/tobor
https://osbornepro.com
https://writeups.osbornepro.com
https://btpssecpack.osbornepro.com
https://www.powershellgallery.com/profiles/tobor
https://www.hackthebox.eu/profile/52286
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges


.INPUTS
System.String[]


.OUTPUTS
System.String[]
#>
    [OutputType([System.String[]])]
    [CmdletBinding(DefaultParameterSetName="Credential")]
        param(
            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [ValidateSet('Sftp','Ftp')]
            [String]$Protocol = "Sftp",

            [Parameter(
                Mandatory=$True,
                HelpMessage="[H] Enter the FQDN, IP address, or hostname of the WinSCP server`n  [-] EXAMPLE: sftp.domain.com "
            )]  # End Parameter
            [String]$Server,

            [Parameter(
                Mandatory=$False,
                HelpMessage="[H] Enter the destination port for the WinSCP server`n  [-] EXAMPLE: sftp.domain.com "
            )]  # End Parameter
            [ValidateRange(0, 65535)]
            [Int]$Port = 0,

            [Parameter(
                Mandatory=$True,
                HelpMessage="[H] Define where to save your files too `n  [-] EXAMPLE: 'C:\Temp\file1.txt', 'C:\file2.txt' "
            )]  # End Parameter
            [String[]]$LocalPath,

            [Parameter(
                Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$False,
                HelpMessage="[H] Define where to download files from on the WinSCP server `n  [-] EXAMPLE: C:\Temp\ "
            )]  # End Parameter
            [String[]]$RemotePath,

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [Switch]$EnumerateDirectory,

            [Parameter(
                Mandatory=$True,
                ParameterSetName="Credential"
            )]  # End Parameter
            [ValidateNotNull()]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential = [System.Management.Automation.PSCredential]::Empty,

            [Parameter(
                ParameterSetName="Credentials",
                Mandatory=$True,
                HelpMessage="[H] Enter the username to authenticate to the WinSCP server with`n  [-] EXAMPLE: sftpadmin "
            )]  # End Parameter
            [String]$Username,

            [Parameter(
                ParameterSetName="Credentials",
                Mandatory=$True,
                HelpMessage="[H] Enter the password to authenticate to the WinSCP server with for the user specified `n  [-] EXAMPLE: (ConvertTo-SecureString -String 'Password123!' -AsPlainText -Force) `n  [-] EXAMPLE: (Read-Host -Prompt 'Enter password' -AsSecureString) "
            )]  # End Parameter
            [SecureString]$Password,

            [Parameter(
                ParameterSetName="Key",
                Mandatory=$True,
                HelpMessage="[H] Enter the username to authenticate to the WinSCP server with`n  [-] EXAMPLE: sftpadmin "
            )]  # End Parameter
            [String]$KeyUsername,

            [Parameter(
                ParameterSetName="Key",
                Mandatory=$True,
                HelpMessage="[H] Define the location of the .ppk certificate file to authenticate with `n  [-] EXAMPLE: C:\Users\Administrator\.ssh\id_rsa.ppk "
            )]  # End Parameter
            [ValidateScript({$_ -like "*.ppk"})]
            [String]$SshPrivateKeyPath,

            [Parameter(
                ParameterSetName="Key",
                Mandatory=$True,
                HelpMessage="[H] Enter the SSH private key password to authenticate to the WinSCP server with `n  [-] EXAMPLE: (ConvertTo-SecureString -String 'Password123!' -AsPlainText -Force) `n  [-] EXAMPLE: (Read-Host -Prompt 'Enter password' -AsSecureString) "
            )]  # End Parameter
            [SecureString]$SshPrivateKeyPassPhrase,

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [ValidateSet('AcceptNew','GiveUpSecurityAndAcceptAny','Check')]
            [String]$HostKeyPolicy = "AcceptNew",

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [ValidateSet('Active','Passive')]
            [String]$FTPMode = "Passive",

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [ValidateSet('None','Implicit','Explicit')]
            [String]$FTPEncryption,

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [Switch]$TrustCertificate,

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [Int]$Timeout = 15, # Seconds

            [ValidateNotNullOrEmpty()]
            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [ValidateScript({$_.Name -eq "WinSCPnet.dll"})]
            [System.IO.FileInfo]$WinScpDllPath = "$env:ProgramData\WinSCP\WinSCPnet.dll"
        )  # End param

BEGIN {

    Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Loading the WinSCP assembly from $WinScpDllPath"
    Add-Type -Path $WinScpDllPath -Verbose:$False

} PROCESS {

    Write-Debug -Message "[d] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') ParameterSetName value is $($PSCmdlet.ParameterSetName)"
    Switch ($PSCmdlet.ParameterSetName) {

        'Credentials' {

            $SessionOptions = New-Object -TypeName WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::$Protocol;
                PortNumber = $Port;
                HostName = $Server;
                UserName = $Username;
                SecurePassword = $Password;
                FtpMode = [WinSCP.FtpMode]::$FTPMode;
                Timeout = $Timeout;
            }  # End $SessionOptions

        } 'Key' {

            $SessionOptions = New-Object -TypeName WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::$Protocol;
                PortNumber = $Port;
                HostName = $Server;
                UserName = $KeyUsername;
                SshPrivateKeyPath = $SshPrivateKeyPath;
                PrivateKeyPassphrase = $SshPrivateKeyPassPhrase;
                FtpMode = [WinSCP.FtpMode]::$FTPMode;
                Timeout = $Timeout;
            }  # End $SessionOptions

        } 'Credential' {

            $SessionOptions = New-Object -TypeName WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::$Protocol;
                PortNumber = $Port;
                HostName = $Server;
                UserName = $Credential.Username;
                SecurePassword = $Credential.Password;
                FtpMode = [WinSCP.FtpMode]::$FTPMode;
                Timeout = $Timeout;
            }  # End $SessionOptions

        } Default {

            Throw "[x] Unable to determine a required credential parameter set name"

        }  # End Switch Options

    }  # End Switch

    Switch ($Protocol) {

        'Ftp' {

            $SessionOptions.FtpSecure = $FTPEncryption
            If ($TrustCertificate.IsPresent) {

                $SessionOptions.GiveUpSecurityAndAcceptAnyTlsHostCertificate = 1

            }  # End If

            If ($Port -eq 0 -and $SessionOptions.FtpSecure -like "Implicit") {

                $WritePort = 990

            } ElseIf ($Port -eq 0 -and $SessionOptions.FtpSecure -like "Explicit") {

                $WritePort = 21

            } Else {
            
                $WritePort = $Port

            }  # End If ElseIf Else

        } 'Sftp' {

            $SessionOptions.SshHostKeyPolicy = [WinSCP.SshHostKeyPolicy]::$HostKeyPolicy
            $WritePort = 22

        }  # End Switch Options

    }  # End Switch

    $Session = New-Object -TypeName WinSCP.Session
    Try {
    
        Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Establishing $Protocol session"
        $Session.Open($SessionOptions)
        $TransferOptions = New-Object -TypeName WinSCP.TransferOptions
        $TransferOptions.TransferMode = [WinSCP.TransferMode]::Binary

        Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Transferring $($Path.Count) files over SFTP connection from $Server port $WritePort to $Destination"
        ForEach ($File in $Path) {

            $TransferResult = $Session.GetFiles($RemotePath, $LocalPath, $False, $TransferOptions)
            $TransferResult.Check() 
            ForEach ($Transfer in $TransferResult.Transfers) {

                Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Download of $($Transfer.FileName) succeeded"

            }  # End ForEach

        }  # End ForEach

    } Finally {

        If ($EnumerateDirectory.IsPresent) {
    
            $Directory = $Session.ListDirectory($Destination)
            $SubDirs = $Directory.Files.FullName
    
            $Output = @()
            ForEach ($Sub in $SubDirs) {
            
                $Output += $Sub
        
            }  # End ForEach

            Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') $($Output.Count) items returned from $Destination"

        }  # End If

        Write-Verbose -Message "[v] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Closing the $Protocol session"
        $Session.Dispose()

    }  # End Try Finally

} END {

    Return $Output

}  # End B P E

}  # End Function Invoke-WinSCPDownload
