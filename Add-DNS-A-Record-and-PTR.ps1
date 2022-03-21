# This script can be used to create a new DNS A record and associated PTR record.
# If a reverse lookup zone does not already exist on the DNS server it will be created

$Zones = Get-DnsServerZone | Select-Object -Property ZoneName
If ($Null -ne $Zones) {

    $Zones | Out-String
    $ZoneName = Read-Host -Prompt "`nEnter a ZoneName from above to add the A record too"
    $Name = Read-Host -Prompt "Enter the hostname (not FQDN) you are creating a DNS record for"
    $IPv4Address = Read-Host -Prompt "Enter the IPv4Address for the A record"

    Add-DnsServerResourceRecordA -Name $Name -ZoneName $ZoneName -AllowUpdateAny -IPv4Address $IPv4Address -CreatePtr -TimeToLive 01:00:00 -ErrorVariable NoPTR -ErrorAction SilentlyContinue
  
    If ($NoPTR) {

      $NetworkID = Read-Host -Prompt "Enter a subnet ID for the PTR record. `nEXAMPLE: 172.16.32.0/24'"
      Add-DnsServerPrimaryZone -DynamicUpdate Secure -NetworkId $NetworkID -ReplicationScope Domain
      Add-DnsServerResourceRecordA -Name $Name -ZoneName $ZoneName -AllowUpdateAny -IPv4Address $IPv4Address -CreatePtr -TimeToLive 01:00:00
  
    }  # End Try Catch

}  # End If
Else {

    Throw "[x] No DNS zones were found. This must be executed on a DNS server using elevated permissions"

}  # End Else
