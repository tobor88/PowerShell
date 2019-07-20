<#
.Synopsis
    Get-PublicIp is used to get the public ip address of the local device.

.DESCRIPTION
    Get-PublicIp gets the public IP address of the local machine and displays other info as well such as Provider, City, etc.

.NOTES
    Author: Rob Osborne
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
   Get-PublicIP 
#>

Function Get-PublicIp {
    [CmdletBinding()]
        param()

    $IpInfo = Invoke-RestMethod https://ipinfo.io/json 
    
    if ($IpInfo -like $NULL) {
    
      $IpInfo = Invoke-RestMethod http://ipinfo.io/json 
    
    } # End If
    
    else {
    
      Write-Warning "Could not connect to API at http://ipinfo.io/json. Check internet connection and site availability."
    
      break
    
    } # End Else
    
    $obj = New-Object -TypeName PsObject -Property @{IPv4 = $IpInfo.Ip 
                                              Hostname = $IpInfo.Hostname
                                              City = $IpInfo.City
                                              Region = $IpInfo.Region
                                              Country = $IpInfo.Country
                                              GeoLoc = $IpInfo.Loc
                                              Organization = $IpInfo.Org
    } # End Properties
    
    $obj

} # End Function

Get-PublicIp
