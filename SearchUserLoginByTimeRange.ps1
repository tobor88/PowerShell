# This script can be used to search the Windows Event Log by a persons username to pull successful sign ins from a specified time range
# You will be asked for the users SamAccoutName and be asked to define a start time and end time.

# Questions for required info for search
$SamAccountName = Read-Host -Prompt "What is the user's SamAccountName? EXAMPLE: rob.osborne"
$Start = Read-Host -Prompt "Enter a start date to search for EXAMPLE: 11/1/21 `nEXAMPLE: 11/1/21 01:22:00"
$End = Read-Host -Prompt "Enter and end date to search EXAMPLE: 11/10/21 `nEXAMPLE: 11/1/21 01:22:00"

# Regex to return the IP address of the device they signed into
[regex]$Ipv4Regex = ‘\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b’

# XML to Search
$Xml = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">
        *[System[(EventID=4624) and TimeCreated[@SystemTime&gt;='$(Get-Date -Date $Start -Format 'yyyy-MM-ddThh:m:ss.000Z')' and @SystemTime&lt;='$(Get-Date -Date $End -Format 'yyyy-MM-ddThh:m:ss.999Z')']] and EventData[Data[@Name='TargetUserName']='$SamAccountName']]
    </Select>
  </Query>
</QueryList>
"@

Write-Output "[*] Performing your query..."
$UserLogonEvents = Get-WinEvent -FilterXML $Xml

$Obj = @()
ForEach ($IP in $UserLogonEvents) {

    $TimeCreated = $IP.TimeCreated
    [array]$IPAddress = ($IP.Message -Split "`n" | Select-String -Pattern $Ipv4Regex | Select-Object -Unique | Out-String).Replace("	Source Network Address:	","").Trim()

    $Obj += New-Object -TypeName PSObject -Property @{Username=$SamAccountName;IPAddress=$IPAddress;Time=$TimeCreated}
    
}  # End ForEach

$Obj
    
$Answer = Read-Host -Prompt "Would you like to export the above results to a CSV file? [y/N]"
If ($Answer -like "y*") {

    Write-Output "[*] Exporting results to $env:USERPROFILE\Documents\LoginResult.csv"
    $Obj | Export-Csv -Path "$env:USERPROFILE\Documents\LoginResult.csv" -Delimiter ',' -NoTypeInformation -Force
    
    Write-Output "[*] Opening file"
    Start-Process -FilePath "$env:USERPROFILE\Documents\LoginResult.csv"

}  # End If
