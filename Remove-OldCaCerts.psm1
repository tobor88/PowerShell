<#
.Synopsis
    Remove-OldCaCerts is a cmdlet that is used to remove all old CA Certificates from a computer.

.DESCRIPTION
    Remove an old Certificate Authorities certificates from a computer.

.NOTES
    Author: Rob Osborne
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
   Remove-OldCaCerts -Verbose

.EXAMPLE
   Remove-OldCaCerts -ComputerName "$env:COMPUTERNAME" -Verbose
#>

Function Remove-OldCaCerts {
    [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True,
                Position=0,
                HelpMessage="Enter the distinguished name of the root ca that is now old. Example: 'CN=ROOT-CA, DC=OsbornePro, DC=COM'")] # End Parameter
            [ValidateNotNullorEmpty()]
        [string[]]$CAIssuer,


            [Parameter(Mandatory=$False,
                Position=1,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter the name of the local computer or a remote computer")] # End Parameter
            [ValidateNotNullorEmpty()]
        [string[]]$ComputerName ) # End param

    If ($null -eq $ComputerName)
    {

        $ComputerName = "$env:COMPUTERNAME"

    } #End If

    Write-Verbose "Creating Certificate Store Objects for LocalMachine..."

    $CertStoreLocalMachine = New-Object System.Security.Cryptography.X509Certificates.X509Store  -ArgumentList  "\\$($Computername)\My", "LocalMachine"


    Write-Verbose "Finding all certificates that have an Issuer of USAV-Root-CA-1..."

    $OldCACertificates = $CertStoreLocalMachine.Certificates | Select-Object -Property * | Where-Object {$_.Issuer -eq $CAIssuer}

    $Thumbprints = $OldCACertificates.Thumbprint

    $OldCACertificates | Select-Object -Property 'Issuer','Subject','Thumbprint','FriendlyName'

    Write-Verbose "The above certificates are about to be removed. Press Enter to continue or Ctrl+C to quit. "

    pause

    Write-Verbose "Removing certificates..."

    ForEach ($Thumbprint in $OldCACertificates)
    {
        Get-ChildItem "Cert:\LocalMachine\My\$Thumbprint" | Remove-Item

    } # End ForEach

} # End Function Remove-OldCaCerts
