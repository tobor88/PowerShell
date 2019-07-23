<#
.SYNOPSIS
    Set-StaticIPv4 cmdlet is used to automatically assign a static IPv4 address that is not in use.

.DESCRIPTION
    This cmdlet was created for sysadmins and does not require any switches. 

.NOTES
    Author: Rob Osborne 
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.com

.EXAMPLE
    Set-StaticIPv4 -Verbose
#>
Function Set-StaticIPv4 {
    [CmdletBinding()]
        param()
        
    BEGIN {
    
      Write-Verbose "If you have not already set the below options to match your environment edit the BEGIN variables."
      
      $MaskBits = 24
      $Gateway = "192.168.1.1"
      $Dns = '("208.67.222.222","208.67.220.220")'
      $IPType = "IPv4"
      $IpId = (Get-Random -Maximum 253 -Minimum 10)
      $IP = "192.168.1.$IpId"
    
    } # End BEGIN
    
    PROCESS {

        do {

          if (Test-NetConnection $Ip | Select-Object -Property PingSucceeded | Where-Object -Property Status -EQ $true) {

                  $IpId = (Get-Random -Maximum 253 -Minimum 10)

                  $IP = "192.168.1.$IpId"

          } # End If

          else {
          
              Write-Verbose "Retrieving network adapter to configure"

              $Adapter = Get-NetAdapter | ? {$_.Status -eq "up"}

              Write-Verbose "Removing existing IP, and Gateway from the IPv4 adapter"

              If (($Adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {

                 $Adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false

              } # End If

              If (($Adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {

                   $Adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false

              } # End if

               Write-Verbose "Configuring the IPv4 address and default gateway"

              $Adapter | New-NetIPAddress -AddressFamily $IPType -IPAddress $IP -PrefixLength $MaskBits -DefaultGateway $Gateway

              Write-Verbose "Configuring the DNS client server IP addresses"

                  $Adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
          } # End Else

        } # End Do
        while (Test-NetConnection $Ip | Select-Object -Property PingSucceeded | Where-Object -Property PingSucceeded -EQ $True)

    } # End PROCESS
    
    END {
    
        $NewIP = (Get-NetIPAddress -AddressFamily IPv4 -PrefixLength $MaskBits).IPAddress
    
        Write-Verbose "Your static IPv4 address is $NewIP"
    
    } # End END
