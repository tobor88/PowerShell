<#
.SYNOPSIS
Set-StaticIPv4 cmdlet is used to automatically assign a static IPv4 address that is not in use.


.DESCRIPTION
This cmdlet is used to statically assign an IPv4 Address to a devices interfaces.
Useful if you do not know any available IPv4 Addresses and do not feel like looking them up


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
Set-StaticIPv4 -FirstThreeOfIpAddress "192.168.1" -DefaultGateway "192.168.1.1" -ServerAddresses "208.67.222.222","208.67.220.220"
This example will use a defauly prefix length of 24. I recommend using the -Verbose switch

.EXAMPLE
Set-StaticIPv4 -FirstThreeOfIpAddress "172.16.1" -DefaultGateway "172.16.1.1" -ServerAddresses "8.8.8.8" -PrefixLength 22 -Verbose
This example defines the Prefix Length
#>
Function Set-StaticIPv4 {
    [CmdletBinding()]
        param(
            [Parameter(Position=0,
                Mandatory=$True,
                HelpMessage="First 3 values of the subnet to assign the address in. Example: 192.168.1")]
            [string]$FirstThreeOfIpAddress,

            [Parameter(Position=1,
                Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Gateway Address. Example: 192.168.1.1")] # End Parameter
            [string]$DefaultGateway,

            [Parameter(Position=2,
                Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="DNS Servers to use. Example: '208.67.222.222','208.67.220.220'")]
            [string[]]$ServerAddresses,

            [Parameter(Position=3,
                Mandatory=$False,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter the subnet prefix length. If this is not defined it will be set to 24. Example: 24")]
            [int]$PrefixLength) # End param

BEGIN {

    If ($null -eq $PrefixLength) {

        [int]$PrefixLength = 24

    } # End If

    $AddressFamily = "IPv4"
    $IpId = (Get-Random -Maximum 253 -Minimum 10)
    $IP = "$FirstThreeOfIpAddress.$IpId"

} # End BEGIN
PROCESS {

        Do {

          If (Test-Connection $Ip -Count 1) {

              $IpId = (Get-Random -Maximum 253 -Minimum 10)
              $IP = "$FirstThreeOfIpAddress.$IpId"

          } # End If
          Else {

              Write-Verbose "Retrieving network adapter to configure..."
              $Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "up" }

              Write-Verbose "Removing existing IP, and Gateway from the IPv4 adapter"
              $AdapterConfig = $Adapter | Get-NetIPConfiguration
              If (($AdapterConfig.IPv4Address.IPAddress) -and ($AdapterConfig.Ipv4DefaultGateway))) {

                 Write-Verbose "Removing old IPv4 Address"
                 $Adapter | Remove-NetIPAddress -AddressFamily $AddressFamily -Confirm:$False

                 Write-Verbose "Removing old Default Gateway"
                 $Adapter | Remove-NetRoute -AddressFamily $AddressFamily -Confirm:$False

              } # End If

              Write-Verbose "Configuring the IPv4 address and default gateway"
              $Adapter | New-NetIPAddress -AddressFamily $AddressFamily -IPAddress $IP -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway

              Write-Verbose "Configuring the DNS client server IP addresses"
              $Adapter | Set-DnsClientServerAddress -ServerAddresses $ServerAddresses

          } # End Else

        } While (Test-Connection $Ip -Count 1)

} # End PROCESS
END {

        $NewIP = (Get-NetIPAddress -AddressFamily $AddressFamily -PrefixLength $PrefixLength).IPAddress
        Write-Verbose "Your static IPv4 address is $NewIP"

} # End END

}  # End Function Set-StaticIPv4
