<#
.SYNOPSIS
Disable-MovedDesktops is a cmdlet created for Task Scheduler and does not accept user input. It finds desktops moved from
one subnet to another and compares the desktop naming convention of the subnets to determine if a move occured without permission.

.DESCRIPTION
Disable-MovedDesktops cmdlet finds desktops that were moved from a subnet range in one location and moved to another without permission.
This cmdlet will only work if different locations use different subnets and computer naming conventions have a standard.
This needs to be run on a Domain Controller.

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
Disable-MovedDesktops
#>
Function Disable-MovedDesktops {
    [CmdletBinding()]
        param() # End param

  BEGIN {

    Import-Module ActiveDirectory
    $SmtpServer = "smtpserver.com"
    $FromAddress = "from@osbornepro.com"
    $DisabledComputersOU = "OU=Disabled Computers,DC=osbornepro,DC=com"

    Write-Verbose "Finding all computers with hostname of NJ-/NY-### and gets their IP address
    $ComputersNJ = Get-ADComputer -Filter 'Name -Like "NJ-*"' -Properties Name,IPv4Address
    $ComputersNY = Get-ADComputer -Filter 'Name -Like "NY-*"' -Properties Name,IPv4Address
    $NJRange = "\b(?:(?:10)\.)" + "\b(?:(?:4)\.)" + "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)))" + "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" # 10.4.0.0/16
    $NYIPRange = "\b(?:(?:10)\.)" + "\b(?:(?:2)\.)" + "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" + "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" # 10.2.0.0/16

    Write-Verbose "Checking NJ Computers..."

}  # End BEGIN

PROCESS {

    ForEach ($CompuNJin $ComputersNJ) {

      $HostNameNJ=  $CompuNJDistinguishedName.Tostring()
      $IpAddressNJ= $CompuNJIPv4Address

      Write-Verbose "Comparing subnet ranges looking for hosts in the wrong subnets."
      If ($IpAddressNJ -like $NYIPRange ) {#REMOVE THIS COMMENT TO ADD AN EXCEPTION TO THE RULE# -and ($HostNameNJ -xor "NY-008"))

        Set-ADComputer -Identity $HostNameNJ -Enabled $False | Move-ADobject -Identity $HostNameNJ -TargetPath $Disable
        $MailBodyNJ = "$HostNameNJ was moved from NJ to NY. The computer has been disabled and moved to the Disabled group."
        Send-MailMessage -From $FromEmail -To $FromEmail -Subject "$HostNameNJ Was Disabled" -Body $MailBodyNJ -SmtpServer $SmtpServer

      }  # End If statment

    }  # End ForEach

    Write-Verbose "Checking NY Computers..."

}  # End PROCESS

END {

    ForEach ($CompuNT in $ComputersNT) {

        $HostNameNY =  $CompuNY.DistinguishedName.Tostring()
        $IpAddressNY = $CompuNY.IPv4Address

        If ($IpAddressNY -like $NJIPRange ) {#REMOVE THIS COMMENT TO ADD AN EXCEPTION TO THE RULE# -and ($HostNameNY -xor "NJ-001"))

            Set-ADComputer -Identity $HostNameNY -Enabled $False | Move-ADobject -Identity $HostNameNY -TargetPath $Disable
            $MailBodyNY = "$HostNameNJ was moved from NY to NJ. The computer has been disabled and moved to the Disabled group."
            Send-MailMessage -From $FromEmail -To $FromEmail -Subject "$HostNameNY Was Disabled" -Body $MailBodyNY -SmtpServer $SmtpServer

        }  # End If

      }  # End ForEach

  } # End END

} # End Function Disable-MovedDesktops
