<#
.SYNOPSIS
    This cmdlet is used to get the public ip address of the local device.


.DESCRIPTION
    Get-PublicIp gets the public IP address of the local machine and displays other info as well such as Provider, City, etc.
    This is done thanks to an API at https://ipinfo.io/json


.NOTES
    Author: Rob Osborne
    Alias: tobor
    Contact: rosborne@osbornepro.com


.LINKS
    https://osbornepro.com
    https://writeups.osbornepro.com
    https://github.com/tobor88
    https://gitlab.com/tobor88


.EXAMPLE
    ----------------- EXAMPLE 1 --------------------
   PS> Get-PublicIP

.INPUTS
    None


.OUTPUTS
    PSCustomObject

#>

Function Get-PublicIp {
    [CmdletBinding()]
        param()

    $IpInfo = Invoke-RestMethod -Uri https://ipinfo.io/json

    If ($Null -like $IpInfo)
    {

      $IpInfo = Invoke-RestMethod http://ipinfo.io/json

    }  # End If
    Else
    {

      Throw "Could not connect to API at http://ipinfo.io/json. Check internet connection and site availability."

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
