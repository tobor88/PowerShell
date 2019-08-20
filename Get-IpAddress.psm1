<#
.SYNOPSIS
    Get-IpAddress is a cmdlet created to get the basic IPv4 information.DESCRIPTION
    This cmdlet returns the IPv4 address being used by a device.DESCRIPTION

.DESCRIPTION
    Get-IpAddress returns the IPv4 addresses of a device for easy reading.DESCRIPTION

.NOTES
    Author: Rob Osborne
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
    Get-IpAddress
#>
Function Get-IpAddress
{
    [CmdletBinding()]
        param()

    Try
    {

        Get-NetIpAddress -AddressFamily "IPv4" | Where-Object -Property "PrefixOrigin" -notlike "WellKnown" | Select-Object -ExpandProperty "IpAddress"

    } # End Try
    Catch
    {

        Write-Warning "No network IPv4 Addresses are configured"

    } # End Catch
    
} # End Function Get-IpAddress
