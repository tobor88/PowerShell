# The below script can be used to query Formsite's API.
# This was initially created to view employees who filled out a COVID Symptom Tracker form whenever they went into the office
# It then checks to see if the Windows device that was logged into was accessed in the office (based on IP address) 
# It finally sends an email to remind the employee to fill out the form if they did not already

$Obj1 = @()
$APIKey = "1aaaaaaaa1111aAaAAaa1aAAAAa1AaAAa" # https://www.formsite.com/blog/api-basics/#:~:text=The%20API%20key%20can%20be%20found%20on%20the,the%20end%20and%20separating%20with%20a%20%E2%80%98%26%E2%80%99%20symbol.
[datetime]$Today = Get-Date -Format MM/dd/yyyy
[System.Uri]$Uri = "https://yourformsitelink.formsite.com/api/v2/CompanyName/forms/FormIdentifierCharacters/results"

# Obtaining the Results of the form located at the URL specified above
$Results = Invoke-WebRequest -Method GET -Uri $Uri -Headers @{Authorization = "bearer $APIKey"} | ConvertFrom-Json | Select-Object -ExpandProperty Results

# Filtering those results to obtain the Name, Date, and Time which helps determine whether or not the employee needs to fill out the form today
$Results | ForEach-Object { 
    
    [datetime]$D,$T = ($_.date_finish).Split("T")
    $Date = $D.ToShortDateString()
    If ($Today -eq $Date) {
        
        $Obj1 += New-Object -TypeName PSObject -Property @{Name=$_.items[0].value; Date=$D; Time=$T } 
    
    }  # End If

}  # End ForEach

# The below function is used to query the windows event logs to determine how an employee signed in 
# (This ensures RDP access does not cause any false positives)
Function Get-LastLoginInfo {
    [CmdletBinding(DefaultParameterSetName="Default")]
    param(
        [Parameter(
            Mandatory=$False,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True,
            Position=0)]  # End Parameter
        [String[]]$ComputerName=$env:COMPUTERNAME,

        [Parameter(
            Position=1,
            Mandatory=$False,
            ParameterSetName="Include")]  # End Parameter
        [String]$SamAccountName,
 
        [Parameter(
            Position=1,
            Mandatory=$False,
            ParameterSetName="Exclude")]  # End Parameter
        [String]$ExcludeSamAccountName,
 
        [Parameter(
            Mandatory=$False)]  # End Parameter
        [ValidateSet("SuccessfulLogin", "FailedLogin", "Logoff", "DisconnectFromRDP")]
        [String]$LoginEvent = "SuccessfulLogin",
 
        [Parameter(
            Mandatory=$False)]  # End Parameter
        [Int]$PreviousHours = 13,
 
        [Parameter(
            Mandatory = $False)]
        [Int]$MaxEvents = 1024,

        [System.Management.Automation.PSCredential]$Credential
    )  # End param
 
 
    BEGIN {

        $StartDate = (Get-Date).AddHours(-$PreviousHours)
        Switch ($LoginEvent) {

            SuccessfulLogin   {$EventID = 4624}
            FailedLogin       {$EventID = 4625}
            Logoff            {$EventID = 4647}
            DisconnectFromRDP {$EventID = 4779}

        }  # End Switch

    }  # End BEGIN
 
    PROCESS {

        ForEach ($Computer in $ComputerName) {

            Try {

                $Computer = $Computer.ToUpper()
                $Time = "{0:F0}" -f (New-TimeSpan -Start $StartDate -End (Get-Date) | Select-Object -ExpandProperty TotalMilliseconds) -as [int64]
 
                If ($PSBoundParameters.ContainsKey("SamAccountName")) {

                    $EventData = "
                        *[EventData[
                                Data[@Name='TargetUserName'] != 'SYSTEM' and
                                Data[@Name='TargetUserName'] != '$($Computer)$' and
                                Data[@Name='TargetUserName'] = '$($SamAccountName)'
                            ]
                        ]
                    "
                }  # End If
 
                If ($PSBoundParameters.ContainsKey("ExcludeSamAccountName")) {
                    $EventData = "
                        *[EventData[
                                Data[@Name='TargetUserName'] != 'SYSTEM' and
                                Data[@Name='TargetUserName'] != '$($Computer)$' and
                                Data[@Name='TargetUserName'] != '$($ExcludeSamAccountName)'
                            ]
                        ]
                    "
                }  # End If
 
                If ((-not $PSBoundParameters.ContainsKey("SamAccountName")) -and (-not $PSBoundParameters.ContainsKey("ExcludeSamAccountName"))) {
                    $EventData = "
                        *[EventData[
                                Data[@Name='TargetUserName'] != 'SYSTEM' and
                                Data[@Name='TargetUserName'] != '$($Computer)$'
                            ]
                        ]
                    "
                }  # End If
 
                $Filter = @"
                    <QueryList>
                        <Query Id="0">
                            <Select Path="Security">
                            *[System[
                                    Provider[@Name='Microsoft-Windows-Security-Auditing'] and
                                    EventID=$EventID and
                                    TimeCreated[timediff(@SystemTime) &lt;= $($Time)]
                                ]
                            ]
                            and
                                $EventData
                            </Select>
                        </Query>
                    </QueryList>
"@
 
                If ($PSBoundParameters.ContainsKey("Credential")) {

                    $EventLogList = Get-WinEvent -ComputerName $Computer -FilterXml $Filter -Credential $Credential -ErrorAction Stop
     
                }  # End If
                Else {

                    $EventLogList = Get-WinEvent -ComputerName $Computer -FilterXml $Filter -ErrorAction Stop

                }  # End Else
 
 
                $Output = ForEach ($Log in $EventLogList) {

                    $TimeStamp = $Log.timeCReated.ToString('MM/dd/yyyy hh:mm tt') -as [DateTime]
 
                    Switch ($Log.Properties[8].Value) {

                        2  {$LoginType = 'Interactive'}
                        3  {$LoginType = 'Network'}
                        4  {$LoginType = 'Batch'}
                        5  {$LoginType = 'Service'}
                        7  {$LoginType = 'Unlock'}
                        8  {$LoginType = 'NetworkCleartext'}
                        9  {$LoginType = 'NewCredentials'}
                        10 {$LoginType = 'RemoteInteractive'}
                        11 {$LoginType = 'CachedInteractive'}

                    }  # End Switch
 
                    If ($LoginEvent -eq 'FailedLogin') {

                        $LoginType = 'FailedLogin'

                    }  # End If
 
                    If ($LoginEvent -eq 'DisconnectFromRDP') {

                        $LoginType = 'DisconnectFromRDP'

                    }  # End If
 
                    If ($LoginEvent -eq 'Logoff') {

                        $LoginType = 'Logoff'
                        $UserName = $Log.Properties[1].Value.toLower()

                    }  # End If
                    Else {

                        $UserName = $Log.Properties[5].Value.toLower()

                    }  # End Else
 
                    [PSCustomObject]@{
                        ComputerName = $Computer
                        TimeStamp    = $TimeStamp
                        UserName     = $UserName
                        LoginType    = $LoginType
                    }  # End Custom Object

                }  # End $Output ForEach
 
                $Output | Select-Object -Property ComputerName, TimeStamp, UserName, LoginType -Unique | Select-Object -First $MaxEvents
 
            }  # End Try
            Catch {

                Write-Error $_.Exception.Message
 
            }  # End Catch

        }  # End ForEach

    }  # End PROCESS
 
}  # End Function Get-LastLoginInfo

# The below checks for the user currently logged into a device and ensures RDP access is excluded
$Console = qwinsta
ForEach ($Line in $Console) {

    If ($Line[1] -like "c") {

        $Tmp = $Line.Split(" ") | Where-Object  { $_.Length  -gt 0 }
        If (($Line[19] -ne " ") -and ($Line[48] -eq "A")) {
                
            $Object = New-Object -TypeName PSObject -Property @{ComputerName="$env:COMPUTERNAME";SessionName=$Tmp[0].Replace('>','');Username=$Tmp[1];ID=$Tmp[2];State=$Tmp[3];Type=$Tmp[4]}

        }  # End If

        $Object = $Object | Select-Object -First 1
        $Email = $Object.Username + "@$env:USERDNSDOMAIN"
        $Session = $Object.SessionName

    }  # End If

}  # End ForEach

# This translates a username into a name. This may be more involved for you depending on how email addresses are created
If ($Object) {

    $FullName = $Object.Username.Replace("."," ") # EXAMPLE: rob.osborne becomes rob osborne

}  # End If
Else {

    Throw "[x] No users are locally signed into $env:COMPUTERNAME"

}  # End Else

$LastLoginInfo = Get-LastLoginInfo -SamAccountName $Object.Username -PreviousHours 13 -MaxEvents 1024 -LoginEvent SuccessfulLogin 


If (($LastLoginInfo) -and ($Obj1.Name.Trim() -NotContains $FullName.Replace(".","").Split("-")[0]) + " ") {

    # Used to authenticate email sending. You can use another one of my scripts to not display a clear text password using https://github.com/tobor88/PowerShell/blob/master/Hide-PowerShellScriptPassword.ps1
    $User = "$env:USERNAME@$env:USERDNSDOMAIN"
    $String = "asdf...."
    $Key = ("111", "11", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "11", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "11", "111", "111", "111", "111", "111", "111", "111")
    $Argument2 =  ($String | ConvertTo-SecureString -Key $Key)

    # Get a list of IP addresses the device is connected too
    $IPAddresses = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $Null } | Select-Object -ExpandProperty IPAddress
    
    # Below we are defining subnets that exist inside your network. This tells us if the person filled out he form while at home or in the office
    If ($IPAddresses -like "10.0.3.*" -or $IPAddresses -like "10.0.4.*" -or $IPAddresses -like "10.0.5.*" -or $IPAddresses -like "10.0.6.*" -or $IPAddresses -like "10.0.7.*" -or $IPAddresses -like "10.0.8.*" -or $IPAddresses -like "10.0.9.*") {
    
        If (($Session -eq 'console') -and ($FullName -notlike "Exclude UserbyName")) {

            $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Argument2
            Send-MailMessage -Credential $Cred -UseSsl -Priority Normal -Port 587 -SmtpServer smtp.office365.com -From $User -To $Email -Subject "ACTION REQUIRED: Fill Out Health Tracker" -Body "Hello, $FullName`n`nThis is a friendly reminder to complete the health tracker form. `n`nOur records indicate you are in the office and have not completed the Heath Tracker form at $($Uri | Out-String) Please fill it out for our compliance with health standards. Thank you"
 
        }  # End If

    }  # End If
    Else {

        Write-Output "[x] $env:COMPUTERNAME is not assigned an IP address in our Subnets"

    }  # End Else

}  # End If
