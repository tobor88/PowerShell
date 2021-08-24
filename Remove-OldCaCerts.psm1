<#
.SYNOPSIS
This cmdlet is a cmdlet that is used to remove all old CA Certificates from a computer.


.DESCRIPTION
Remove an old Certificate Authorities certificates from a computer. This is accomplished by defining a computer to delete the old CA Certs from.DESCRIPTION
If no computername is defined the local computer becomes the default computer to remove old CA Certificates from.DESCRIPTION
The CA issuer also needs to be defined. This can be found in your envrionemt by opening an certs in MMC local computer certificates Add in and viewing the CA Issuer.DESCRIPTION
The format of the CA issuer needs to be in Distinguished name format. Example: 'CN=CAIssuer,DC=domain,DC=com'


.PARAMETER ComputerName
Specifies a remote computer. The default is the local computer. Type the NetBIOS name, an Internet Protocol (IP) address, or a fully qualified domain name (FQDN) of a remote computer. To specify the local computer, type the computer name, a dot (.), or localhost.


.INPUTS
Computer Name
This cmdlet accepts an input objects specified with the ComputerName parameter.


.OUTPUTS
No output. This deletes old CA Certificates


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

.EXAMPLE
Remove-OldCaCerts -ComputerName Desktop01 -CAIssuer <string[] Distinguished Name of CA Issuer> [-Verbose]
# This command deletes all CA Certificates off a remote computer in the Cert:\LocalMachine\My drive

#>

Function Remove-OldCaCerts {
    [CmdletBinding()]
        param(
            [Parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter the name of the local computer or a remote computer")] # End Parameter
        [string[]]$ComputerName,

            [Parameter(Mandatory=$True,
                Position=1,
                HelpMessage="Enter the distinguished name of the root ca that is now old. Example: 'CN=ROOT-CA, DC=OsbornePro, DC=COM'")] # End Parameter
            [ValidateNotNullorEmpty()]
        [string[]]$CAIssuer ) # End param

    If ($null -eq $ComputerName) {

        $ComputerName = "$env:COMPUTERNAME"

    } #End If

    Write-Verbose "Creating Certificate Store Objects for LocalMachine..."
    $CertStoreLocalMachine = New-Object 'System.Security.Cryptography.X509Certificates.X509Store'  -ArgumentList  "\\$($Computername)\My", "LocalMachine"

    Write-Verbose "Finding all certificates that have an Issuer of $CAIssuer..."
    $OldCACertificates = $CertStoreLocalMachine.Certificates | Select-Object -Property * | Where-Object { $_.Issuer -eq $CAIssuer }
    $Thumbprints = $OldCACertificates.Thumbprint
    $OldCACertificates | Select-Object -Property 'Issuer','Subject','Thumbprint','FriendlyName'

    Write-Verbose "The above certificates are about to be removed. Press Enter to continue or Ctrl+C to quit. "
    pause

    Write-Verbose "Removing certificates..."
    ForEach ($Thumbprint in $OldCACertificates) {

        Get-ChildItem "Cert:\LocalMachine\My\$Thumbprint" | Remove-Item -Force

    } # End ForEach

} # End Function Remove-OldCaCerts
