<#
.Synopsis
    Enable-Dhcp is a cmdlet that is used for enabling DHCP on a local computer's active network adapters. 

.DESCRIPTION
    Enables DHCP for IPv4 Network adapters on a local computer.

.NOTES
    Author: Rob Osborne 
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
   Enable-Dhcp -ComputerName $ComputerName 
.EXAMPLE
   Enable-Dhcp -ComputerName $ComputerName -Verbose
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

        if ($interface.Dhcp -eq "Disabled") {
 
            Write-Verbose "Remove existing gateway"

            if (($Interface | Get-NetIPConfiguration).Ipv4DefaultGateway) {
 
                $Interface | Remove-NetRoute -Confirm:$false
 
            } # End If
 
        Write-Verbose "Enabling DHCP"
 
        $Interface | Set-NetIPInterface -DHCP Enabled

        Write-Verbose "Configuring the DNS Servers automatically"

        $Interface | Set-DnsClientServerAddress -ResetServerAddresses

        } # End If

        Else {

        Write-Host "DHCP is already enabled"

        }
    } # End PROCESS
    
    END {
    
        Write-Verbose "$ComputerName now using DHCP to obtain and IPv4 address."
    
    } # End END
