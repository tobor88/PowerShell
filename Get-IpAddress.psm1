<#
.SYNOPSIS
Get-IpAddress is a cmdlet created to get the basic IPv4 information.DESCRIPTION
This cmdlet returns the IPv4 address being used by a device.DESCRIPTION


.DESCRIPTION
Get-IpAddress returns the IPv4 addresses of a device for easy reading.DESCRIPTION


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
Get-IpAddress
#>
Function Get-IpAddress {
    [CmdletBinding()]
        param()

    Try {

        Get-NetIpAddress -AddressFamily "IPv4" | Where-Object -Property "PrefixOrigin" -notlike "WellKnown" | Select-Object -ExpandProperty "IpAddress"

    } # End Try
    Catch {

        Write-Warning "No network IPv4 Addresses are configured"

    } # End Catch

} # End Function Get-IpAddress
