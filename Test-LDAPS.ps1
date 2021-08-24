<#
.SYNOPSIS
This cmdlet is used to verify your domain controller is correctly configured to accept LDAP over SSL connections


.PARAMETER ComputerName
Specifies one computer name or a comma-separated array of computer names. This cmdlet accepts
ComputerName objects from the pipeline or variables.

Type the NetBIOS name, an IP address, or a fully qualified domain name of a remote computer. To specify the
local computer, type the computer name, a dot `.`, or localhost.

This parameter doesn't rely on PowerShell remoting. You can use the ComputerName parameter even if your
computer isn't configured to run remote commands.


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


.INPUTS
System.String
Accepts computer names from the pipeline or variables. (Domain Controllers are of course required)


.OUTPUTS
PSCustomObject

#>
Function Test-LDAPS {
    [CmdletBinding()]
        param (
            [Parameter(
                Mandatory=$True,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True,
                HelpMessage='Enter the hostname or ip address of a domain controller to test LDAPS on. Separate multiple values with a comma')]
            [Alias('cn','Computer','Server')]
	        [String[]]$ComputerName
        )  # End param

BEGIN {

    $Obj = @()

}  # End BEGIN
PROCESS {

    ForEach ($Computadora in $ComputerName) {

        Try {

            Write-Verbose "[*] Attempting to connect to port 636 on $Computadora"
            $LDAPS = [ADSI]("LDAP://" + $Computadora + ":636")

        }  # End Try
        Catch {

            Write-Verbose "[x] Trouble connecting to $Computadora on port 636"
            $Error[0]

        }  # End Catch

        If ($LDAPS.Path) {

            $Protocol = 'LDAPS'

        }  # End If
        Else {

            $Protocol = 'x'

        }  # End Else

        $Obj += New-Object -TypeName PSObject -Property @{Server="$Computadora";Protocol="$Protocol"}

    }  # End ForEach

}  # End PROCESS
END {
    
    $Obj

}  # End END

} # End Test-LDAPS
