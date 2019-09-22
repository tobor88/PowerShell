Function Invoke-PingSweep
{
    [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True,
                Position=0,
                HelpMessage="Enter an IPv4 subnet ending in 0. Example: 10.0.9.0")]
            [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.0")]
            [string]$Subnet,

            [ValidateRange(1,255)]
            [int]$Start = 1,

            [ValidateRange(1,255)]
            [int]$End = 254,

            [ValidateRange(1,10)]
            [int]$Count = 1) # End param

        #[array]$LocalIPAddress = Get-NetIPAddress -AddressFamily "IPv4" | Where-Object { ($_.InterfaceAlias -notmatch "Bluetooth|Loopback") -and ($_.IPAddress -notlike "169.254.*") }  | Select-Object -Property "IPAddress"

        [string]$ClassC = $Subnet.Split(".")[0..2] -Join "."

        [array]$Results = @()

        [int]$Timeout = 500

        Write-Host "The below IP Addressess are currently active." -ForegroundColor "Green"

        For ($i = 0; $i -le $End; $i++)
        {

            [string]$IP = "$ClassC.$i"

            #If ($IP -notlike $LocalIPAddress)
          #  {

                $Filter = 'Address="{0}" and Timeout={1}' -f $IP, $Timeout

                If ((Get-WmiObject "Win32_PingStatus" -Filter $Filter).StatusCode -eq 0)
                {

                    Write-Host $IP -ForegroundColor "Yellow"

                } # End If

            #} # End If

      } # End For

} # End Function Invoke-PingSweep
