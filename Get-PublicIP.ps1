Function Get-PublicIp {
<#
.SYNOPSIS
This cmdlet is used to get the public ip address of the local device.


.DESCRIPTION
Get-PublicIp gets the public IP address of the local machine and displays other info as well such as Provider, City, etc.
This is done thanks to an API at https://ipinfo.io/json


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
----------------- EXAMPLE 1 --------------------
PS> Get-PublicIP

.INPUTS
None


.OUTPUTS
PSCustomObject

#>
    [CmdletBinding()]
        param()

    $UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:104.0) Gecko/20100101 Firefox/104.0'
    $IpInfo = Invoke-RestMethod -Uri https://ipinfo.io/json -UseBasicParsing -Method GET -UserAgent $UserAgent

    If ($Null -like $IpInfo) {

      Throw " [x] Could not connect to API at http://ipinfo.io/json. Check internet connection and site availability."

    }  # End Else

    $Obj = New-Object -TypeName "PsObject" -Property @{IPv4 = $IpInfo.Ip
                                              Hostname = $IpInfo.Hostname
                                              City = $IpInfo.City
                                              Region = $IpInfo.Region
                                              Country = $IpInfo.Country
                                              GeoLoc = $IpInfo.Loc
                                              Organization = $IpInfo.Org
    } # End Properties

    $Obj

} # End Function
