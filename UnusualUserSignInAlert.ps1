# This PowerShell function is useful in an environment where users can log into any computer but are assigned maybe 1, 2, or 3+ computers they usually sign into.DESCRIPTION
# What this script does is query the event log for the last 24 hours. Anywhere a successful logon happens (Event ID 4624) for that user is counted.DESCRIPTION
# That count is then compared to he count of how many of those logins were on their assigned devices.DESCRIPTION
# The logins that occured on devices outside the norm are then emailed to the IT admin informing them of the event(s).
#
# This is a little niche to a smaller environment. I learned a lot writing this one and will do a blog on it at https://powershell.org
# IMPORTANTL For this to work you will need a CSV file containing the user and their assigned devices.
#             That info is imported from the CSV before it can be worked with.

Function Get-UserSid
{
    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $True,
                        Position = 0,
                        ValueFromPipeline=$True,
                        ValueFromPipelineByPropertyName=$True,
                        HelpMessage = "Enter a SamAccountName for the user profile. Example: OsbornePro\rob.osborne"
                        )] # End Parameter
            [string[]]$SamAccountName) # End param

    $ObjUser = New-Object System.Security.Principal.NTAccount($SamAccountName)

    $ObjSID = $ObjUser.Translate([System.Security.Principal.SecurityIdentifier])

    If (!($null -eq $ObjSID))
    {

        $ObjSID.Value

    } # End If
    Else
    {

        Write-Warning "SID Lookup failed."

    } # End Else

} # End Function Get-UserSid

$CsvInformation = Import-Csv -Path 'C:\Users\Public\Documents\UserComputerList.csv' -Delimiter ','

ForEach ($Assignment in $CsvInformation)
{
    [string]$SamAccountName = ($Assignment.Name).Replace(' ','.')
    [string]$SID = Get-UserSid -SamAccountName $SamAccountName
    [string]$C = $Device.ComputerName

    [array]$ExpectedLogonEvents = @()
    [array]$UsersComputers = $CsvInformation | Where-Object -Property 'Name' -like $Assignment.Name | Select-Object -Property 'ComputerName'
    [array]$TotalUserLogonEvents = Get-WinEvent -LogName "Security" -FilterXPath "*[System[EventID=4624 and TimeCreated[timediff(@SystemTime) <= 86400000]] and EventData[Data[@Name='TargetUserName']=`'$SamAccountName`']]"

    If ($TotalUserLogonEvents)
    {

        ForEach ($Device in $UsersComputers)
        {

            Write-Host "Setting variable for $C's IP Address"

            [string]$SearchEventName = Get-Variable -Name ($C.Replace('-','')) -ValueOnly

            Set-Variable -Name ($C.Replace('-','')) -Value ( (Resolve-DnsName -Name $C).IPAddress)

            Write-Host "Getting a total of logon events for $SamAccountName on $C..."

            [array]$ExpectedLogonEvents += Get-WinEvent -LogName "Security" -FilterXPath "*[System[EventID=4624 and TimeCreated[timediff(@SystemTime) <= 86400000]] and EventData[Data[@Name='TargetUserName']=`'$SamAccountName`'] and EventData[Data[@Name='IpAddress']=`'$SearchEventName`']]"


        } # End ForEach

        If ($ExpectedLogonEvents)
        {

            Write-Host "Logon events have been found. Comparing total logon events to Expected logon events.. "

            If ($TotalUserLogonEvents.Count -gt $ExpectedLogonEvents.Count)
            {

                Write-Host "Total events is greater than expected events. Expect an email."

                [array]$DifferenceEvents = Compare-Object -ReferenceObject $TotalUserLogonEvents -DifferenceObject $ExpectedLogonEvents

                [string]$MailBody= "$SamAccountName has signed into a deivce outside their assigned computers. Check logs until I find a nice way to send this information. `n`n$UsersComputers`nSID: $SID"

                Send-MailMessage -From "alert@osbornepro.com" -To "notifyme@osbornepro.com" -Subject "AD Event: Unusual Login Occurred" -Body $MailBody -SmtpServer mail.smtp2go.com

            } # End If
            Else
            {

                Write-Host "No unexpected logon events found for $SamAccountName. Hooray!"

            } # End Else

        } # End If

        Else
        {

            Write-Host "No logon attempts found for $SamAccountName on $C"

        } # End Else

    } # End If
    Else
    {

        Write-Host "No logon events were found for $SamAccountName"

    } # End Else

    Remove-Variable ExpectedLogonEvents,TotalUserLogonEvents

} # End ForEach
