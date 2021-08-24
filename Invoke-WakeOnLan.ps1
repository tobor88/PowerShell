<#
.SYNOPSIS
Starts a list of physical machines by using Wake On LAN.
WOL Packet Resource: https://wiki.wireshark.org/WakeOnLAN


.DESCRIPTION
Invoke-WakeOnLan sends a Wake On LAN packet to a machine's MAC address(s) that you specify.


.PARAMETER LinkLayerAddress
Specifies an array of link-layer addresses. The WOL packet gets sent to the link-layer addresses you specify.

The link-layer address is also called the media access control (MAC) address. A link-layer address that uses IPv4 address syntax is a tunnel technology that encapsulates packets over an IPv4 tunnel, such as Intra-Site Automatic Tunnel Addressing Protocol
(ISATAP) or Teredo. A link-layer address of all zeroes indicates that the neighbor is unreachable and the neighbor cache entry does not have a link-layer address entry. An empty link-layer address indicates that the link layer does not use link-layer addresses,
such as on a loopback interface.


.EXAMPLE
Invoke-WakeOnLan -LinkLayerAddress 6045cb236d16
This example sends a wake on lan packet to a computer with the MAC Address 6045cb236d16

.EXAMPLE
Invoke-WakeOnLan
This example sends a wake on lan packet in to the broadcast MAC address FFFFFFFFFF


.INPUTS
None


.OUTPUTS
None


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

#>
Function Invoke-WakeOnLan {
    [CmdletBinding()]
        param(
            [Parameter(
                Mandatory=$False,
                Position=0,
                ValueFromPipeline=$False,
                HelpMessage="MAC address of target machine to wake up")]
            [ValidatePattern("^([0-9A-Fa-f]{2}){5}([0-9A-Fa-f]{2})$")]
            [string]$Mac = "FFFFFFFFFF")  # End param


    Set-StrictMode -Version Latest
    Try {

        $Broadcast = ([System.Net.IPAddress]::Broadcast)

        Write-Verbose "Creating UDP object"
        $UdpClient = New-Object -TypeName Net.Sockets.UdpClient
        $IPEndPoint = New-Object -TypeName Net.IPEndPoint $Broadcast, 9


        $MacAddress = [Net.NetworkInformation.PhysicalAddress]::Parse($Mac.ToUpper())

        Write-Verbose "Building the WOL Packet"
        $Packet =  [Byte[]](,0xFF*6)+($MacAddress.GetAddressBytes()*16)

        Write-Verbose "Broadcasting UDP packets to the IP endpoint of the machine"
        $UdpClient.Send($Packet, $Packet.Length, $IPEndPoint) | Out-Null
        $UdpClient.Close()

    }  # End Try
    Catch {

        $UdpClient.Dispose()
        $Error[0]

    }  # End Catch

}  # End Function Invoke-WakeOnLan
