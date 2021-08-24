<#
.SYNOPSIS
Enable-Dhcp is a cmdlet that is used for enabling DHCP on a local computer's active network adapters.

.DESCRIPTION
Enables DHCP for IPv4 Network adapters on a local computer.

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
Enable-Dhcp
#>
Function Enable-Dhcp {
    [CmdletBinding()]
        param() # End param

    BEGIN {

        $IPType = "IPv4"
        Write-Verbose "Obtaining Active Network Adapters"
        $Adapter = Get-NetAdapter | Where-Object {$_.Status -eq "up"}
        $Interface = $adapter | Get-NetIPInterface -AddressFamily $IPType

    } # End BEGIN
    PROCESS {

        If ($interface.Dhcp -eq "Disabled") {

            Write-Verbose "Remove existing gateway"
            If (($Interface | Get-NetIPConfiguration).Ipv4DefaultGateway) {

                $Interface | Remove-NetRoute -Confirm:$false

            } # End If

        Write-Output "[*] Enabling DHCP"
        $Interface | Set-NetIPInterface -DHCP Enabled

        Write-Output "[*] Configuring the DNS Servers automatically"
        $Interface | Set-DnsClientServerAddress -ResetServerAddresses

        } # End If

        Else {

            Write-Output "[*] DHCP is already enabled"

        }
    } # End PROCESS
    END {

        ipconfig /renew
        Write-Verbose "$ComputerName now using DHCP to obtain and IPv4 address."

    } # End END

} # End Function
