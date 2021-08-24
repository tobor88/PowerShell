<#
.SYNOPSIS
Get-HelpDesk is a cmdlet created for system administrators. It is a combination of script options to simpliy common help desk tasks.


.DESCRIPTION
Get-HelpDesk is compromised of multiple script options and does not use any parameters.


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

.EXAMPLES
Get-HelpDesk
#>
Function Get-HelpDesk {
    param([switch]$Elevated)

    Function Test-Admin {

        $CurrentUser = New-Object -TypeName Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
        $CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    } # End Test-Admin

    If ((Test-Admin) -eq $False) {

        If (!($Elevated)) {

            Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))

        } # End Else

        exit

    } # End If

    $Timeout = new-timespan -Minutes 480 # Time out of script after 8 hours

    Do { # This do is for preventing the script for running longer than 8 hours

        $Domain = "<Domain.com>"
        $PrimaryDC = "<PDC Hostname>"
        $SecondaryDC = "SDC Hostname"
        $PrintServers = "<Print Server hostname>"
        $AzureAdServer = "<Azure Sync Hostname>"
        $Sw = [diagnostics.stopwatch]::StartNew()

    Function MenuMaker{
        param(
            [parameter(Mandatory=$true)][String[]]$Selections,
            [switch]$IncludeExit,
            [string]$Title = $null)

        $Width = If ($Title) {

                        $Length = $Title.Length; $Length2 = $Selections | ForEach-Object {$_.length} | Sort-Object -Descending | Select-Object -First 1;$Length2,$Length | Sort-Object -Descending | Select-Object -First 1

                    } # End if

                    Else {

                        $Selections | ForEach-Object {$_.length} | Sort-Object -Descending | Select-Object -First 1

                    } # End Else

        $Buffer = if (($Width*1.5) -gt 78) {

                    [math]::floor((78-$width)/2)

                    } # End if

                    else {

                        [math]::floor($width/4)

                    } # End else

        if($Buffer -gt 6) { $Buffer = 6 }
            $MaxWidth = $Buffer*2+$Width+$($Selections.count).length+2
            $Menu = @()
            $Menu += "╔"+"═"*$maxwidth+"╗"

        if($Title){
            $Menu += "║"+" "*[Math]::Floor(($maxwidth-$title.Length)/2)+$Title+" "*[Math]::Ceiling(($maxwidth-$title.Length)/2)+"║"
            $Menu += "╟"+"─"*$maxwidth+"╢"
        }

        For($i=1;$i -le $Selections.count;$i++){
            $Item = "$(if ($Selections.count -gt 9 -and $i -lt 10){" "})$i`. "
            $Menu += "║"+" "*$Buffer+$Item+$Selections[$i-1]+" "*($MaxWidth-$Buffer-$Item.Length-$Selections[$i-1].Length)+"║"
        }

        If($IncludeExit){
            $Menu += "║"+" "*$MaxWidth+"║"
            $Menu += "║"+" "*$Buffer+"X - Exit"+" "*($MaxWidth-$Buffer-8)+"║"
        }

        $Menu += "╚"+"═"*$maxwidth+"╝"
        $menu
    }

    do{

        MenuMaker -Selections 'UNLOCK Users Account','RESET Users Password','EXPIRATION of Password','PRINTER Spooler Reset','LIST Installed Applications on a Device','REMOTE Access to a Computer','GROUP Members List','Log User Out of Computer','REBOOT Time','USERNAME to SID','Lookup a Certificate by its Thumbprint','FIRST Name Change','LAST Name Change','Perform a Group Policy Update','Sync Azure and Active Directory','Find a Files Location','Disable Hibernate','Add User to a File or Folders Permssions','JOB Title and Department Change' -Title 'IT Help Desk Tasks' -IncludeExit

        $Response = Read-Host 'Select a task to carry out.'

    } # End Do

    While($Response -notin 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,'x')
    #===================================================================================================================================

if ($Response -eq '1') {

        Invoke-Command -HideComputerName $PrimaryDC -ScriptBlock {

            Import-Module ActiveDirectory

            do {

                $samAccountName = Read-Host "What is the users Sam Account Name Example: firs.last"

                $TestUserExists = Get-AdUser -Identity $samAccountName

            } # End do
            while (!($TestUserExists))

            Write-Host "User account has been confirmed to exist."

            try {

                $TestUserExists | Unlock-ADAccount -Verbose

                Write-Host "-User "$samAccountName" unlocked"

                } # End Try

            catch {

                $Error[0]

                Write-Warning "There was an issue unlocking $samAccountName."

            } # End Catch

        pause

        } # End Invoke-Command

        Clear-Host

    } # End 1 Unlock user account
    #===================================================================================================================================

    elseif ($Response -eq '2') {

        Invoke-Command -HideComputerName $PrimaryDC -ScriptBlock {

            Import-Module ActiveDirectory

            do {

                $Who = Read-Host "Whos password do you want to reset? Example: rob.osborne"

                $TestUserExist = Get-AdUser -Identity $Who

            } # End do
            while (!($TestUserExist))

            $ChangeP = Read-Host 'Do you want them to change their password at next logon Answer this as either 0 for False or 1 for True'

            $BoolValue = try {

                            [System.Convert]::ToBoolean($ChangeP)

                         } # End Try

                         catch [FormatException] {

                            $BoolValue = $false

                         } # End Catch

            function Get-RandomCharacters($length, $characters) {

                $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }

                $private:ofs=""

               return [String]$characters[$random]

            } # https://activedirectoryfaq.com/2017/08/creating-individual-random-passwords/

            function Scramble-String([string]$inputString){

                $characterArray = $inputString.ToCharArray()

                $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length

                $outputString = -join $scrambledStringArray

                return $outputString

            } # https://activedirectoryfaq.com/2017/08/creating-individual-random-passwords/

            $password = Get-RandomCharacters -length 10 -characters 'abcdefghiklmnoprstuvwxyz'

            $password += Get-RandomCharacters -length 4 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'

            $password += Get-RandomCharacters -length 3 -characters '1234567890'

            $password += Get-RandomCharacters -length 3 -characters '!"§$%&/()=?}][{@#*+'

            $password = Scramble-String $password

            Write-Host $password

            $password = Read-Host "`nEnter the users new password or use the one above." | ConvertTo-SecureString -AsPlainText -Force -Verbose

            if (Set-ADAccountPassword $who -Reset -NewPassword $password -PassThru) {

                Set-ADUser -Identity $who -ChangePasswordAtLogon $BoolValue

                Get-AdUser $who -Properties * | Select-Object -Property name, pass*

                Write-Host "Verify their password was changed in the Password Last Set field"

                } # End if

            } # End Invoke

    pause

    Clear-Host

    } # End 2 Reset a users password
    #===================================================================================================================================

    elseif ($Response -eq '3') {

        Invoke-Command -HideComputerName $SecondaryDC -ScriptBlock {

            Write-Host "Example Get-PwdSet rob.osborne"

            Function Get-PwdSet{
                Param([parameter(Mandatory=$true)][string]$user)

                $Use = Get-AdUser $User -Properties PasswordLastSet,PasswordNeverExpires

                If ($Use.PasswordNeverExpires -eq $true) {

                    Write-Host $User "last set their password on " $Use.PasswordLastSet  "this account has a non-expiring password" -ForegroundColor Yellow

                } # End if

                Else {

                    $Til = (([datetime]::FromFileTime((Get-AdUser $User -Properties "msDS-UserPasswordExpiryTimeComputed")."msDS-UserPasswordExpiryTimeComputed"))-(Get-Date)).Days

                } # End Else

                if ($Til -lt "5") {

                    Write-Host $User "last set their password on " $Use.PasswordLastSet "it will expire again in " $Til " days" -ForegroundColor Red

                } # End if

                else {

                    Write-Host $User "last set their password on " $Use.PasswordLastSet "it will expire again in " $Til " days" -ForegroundColor Green

                } # End else

            } # End Function

            do {

                $User = Read-Host "Who is the person in question? Example: rob.osborne"

                $UserExist = Get-AdUser -Identity $User

            } # End do
            while (!($UserExist))

            Get-PwdSet $User

         } # End Invoke-Command

    pause

    Clear-Host

     } # End 3 Lookup password expiration
    #===================================================================================================================================
    elseif ($Response -eq 4) {

        $PrintSpooler = Read-Host -Prompt "Which Print Spooler do you want to restart.`n$PrintServers"

        Try {

            Restart-Service -InputObject $(Get-Service -ComputerName $printspooler -Name spooler) -Force

            Write-Host 'Print Spooler Restarted'

        } # End Try

        Catch {

            if ((Test-NetConnection $PrintSpooler).PingSucceeded) {

                Write-Host "There was an issue restarting the print spooler. `nPing test succeeded. `nTrying to restart the service through a different function."

                Invoke-Command -HideComputerName $PrintSpooler {Restart-Service -Name Spooler -Force}

                Write-Host "Print spooler restarted successfully."

            } # End if

            else {

                Write-Warning "Ping test failed. Connection to print server could not be established."

            } # End else

        } # End Catch

    pause

    Clear-Host

     } # End 4 Reset print spooler
    #===================================================================================================================================

    elseif ($Response -eq 5) {

        $TheDevice = Read-Host "What computer do you want to view the installed software? `n`nTo view software installed on local computer enter localhost."

        if ($TheDevice -notlike $env:COPMUTERNAME) {

        Invoke-Command -HideComputerName $TheDevice -ScriptBlock {

    Function Get-InstalledSoftware {
    <#
    .SYNOPSIS
        Pull software details from registry on one or more computers

    .DESCRIPTION
        Pull software details from registry on one or more computers.  Details:
            -This avoids the performance impact and potential danger of using the WMI Win32_Product class
            -The computer name, display name, publisher, version, uninstall string and install date are included in the results
            -Remote registry must be enabled on the computer(s) you query
            -This command must run with privileges to query the registry of the remote system(s)
            -Running this in a 32 bit PowerShell session on a 64 bit computer will limit your results to 32 bit software and result in double entries in the results

    .PARAMETER ComputerName
        One or more computers to pull software list from.

    .PARAMETER DisplayName
        If specified, return only software with DisplayNames that match this parameter (uses -match operator)

    .PARAMETER Publisher
        If specified, return only software with Publishers that match this parameter (uses -match operator)

    .EXAMPLE
        #Pull all software from c-is-ts-91, c-is-ts-92, format in a table
            Get-InstalledSoftware c-is-ts-91, c-is-ts-92 | Format-Table -AutoSize

    .EXAMPLE
        #pull software with publisher matching microsoft and displayname matching lync from c-is-ts-91
            "c-is-ts-91" | Get-InstalledSoftware -DisplayName lync -Publisher microsoft | Format-Table -AutoSize

    .FUNCTIONALITY
        Computers
    #>
        param (
            [Parameter(
                Position = 0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false
            )]
            [ValidateNotNullOrEmpty()]
            [Alias('CN','__SERVER','Server','Computer')]
                [string[]]$ComputerName = $env:computername,

                [string]$DisplayName = $null,

                [string]$Publisher = $null
        )

        Begin
        {

            #define uninstall keys to cover 32 and 64 bit operating systems.
            #This will yeild only 32 bit software and double entries on 64 bit systems running 32 bit PowerShell
                $UninstallKeys = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
                    "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

        }

        Process
        {

            #Loop through each provided computer.  Provide a label for error handling to continue with the next computer.
            :computerLoop foreach($computer in $computername)
            {

                Try
                {
                    #Attempt to connect to the localmachine hive of the specified computer
                    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)
                }
                Catch
                {
                    #Skip to the next computer if we can't talk to this one
                    Write-Error "Error:  Could not open LocalMachine hive on $computer`: $_"
                    Write-Verbose "Check Connectivity, permissions, and Remote Registry service for '$computer'"
                    Continue
                }

                #Loop through the 32 bit and 64 bit registry keys
                foreach($uninstallKey in $UninstallKeys)
                {

                    Try
                    {
                        #Open the Uninstall key
                            $regkey = $null
                            $regkey = $reg.OpenSubKey($UninstallKey)

                        #If the reg key exists...
                        if($regkey)
                        {

                            #Retrieve an array of strings containing all the subkey names
                                $subkeys = $regkey.GetSubKeyNames()

                            #Open each Subkey and use GetValue Method to return the required values for each
                                foreach($key in $subkeys)
                                {

                                    #Build the full path to the key for this software
                                        $thisKey = $UninstallKey+"\\"+$key

                                    #Open the subkey for this software
                                        $thisSubKey = $null
                                        $thisSubKey=$reg.OpenSubKey($thisKey)

                                    #If the subkey exists
                                    if($thisSubKey){
                                        try
                                        {

                                            #Get the display name.  If this is not empty we know there is information to show
                                                $dispName = $thisSubKey.GetValue("DisplayName")

                                            #Get the publisher name ahead of time to allow filtering using Publisher parameter
                                                $pubName = $thisSubKey.GetValue("Publisher")

                                            #Collect subset of values from the key if there is a displayname
                                            #Filter by displayname and publisher if specified
                                            if( $dispName -and
                                                (-not $DisplayName -or $dispName -match $DisplayName ) -and
                                                (-not $Publisher -or $pubName -match $Publisher )
                                            )
                                            {

                                                #Display the output object, compatible with PowerShell 2
                                                New-Object PSObject -Property @{
                                                    ComputerName = $computer
                                                    DisplayName = $dispname
                                                    Publisher = $pubName
                                                    Version = $thisSubKey.GetValue("DisplayVersion")
                                                    UninstallString = $thisSubKey.GetValue("UninstallString")
                                                    InstallDate = $thisSubKey.GetValue("InstallDate")
                                                } | select ComputerName, DisplayName, Publisher, Version, UninstallString, InstallDate
                                            }
                                        }
                                        Catch
                                        {
                                            #Error with one specific subkey, continue to the next
                                            Write-Error "Unknown error: $_"
                                            Continue
                                        }
                                    }
                                }
                        }
                    }
                    Catch
                    {

                        #Write verbose output if we couldn't open the uninstall key
                        Write-Verbose "Could not open key '$uninstallkey' on computer '$computer': $_"

                        #If we see an access denied message, let the user know and provide details, continue to the next computer
                        if($_ -match "Requested registry access is not allowed"){
                            Write-Error "Registry access to $computer denied.  Check your permissions.  Details: $_"
                            continue computerLoop
                        }

                    }
                }
            }
        }
    }

        Get-InstalledSoftware -Verbose | Select-Object -Property InstallDate, DisplayName

    } # End Invoke-Command

    } # End If

    else {

    Function Get-InstalledSoftware {
    <#
    .SYNOPSIS
        Pull software details from registry on one or more computers

    .DESCRIPTION
        Pull software details from registry on one or more computers.  Details:
            -This avoids the performance impact and potential danger of using the WMI Win32_Product class
            -The computer name, display name, publisher, version, uninstall string and install date are included in the results
            -Remote registry must be enabled on the computer(s) you query
            -This command must run with privileges to query the registry of the remote system(s)
            -Running this in a 32 bit PowerShell session on a 64 bit computer will limit your results to 32 bit software and result in double entries in the results

    .PARAMETER ComputerName
        One or more computers to pull software list from.

    .PARAMETER DisplayName
        If specified, return only software with DisplayNames that match this parameter (uses -match operator)

    .PARAMETER Publisher
        If specified, return only software with Publishers that match this parameter (uses -match operator)

    .EXAMPLE
        #Pull all software from c-is-ts-91, c-is-ts-92, format in a table
            Get-InstalledSoftware c-is-ts-91, c-is-ts-92 | Format-Table -AutoSize

    .EXAMPLE
        #pull software with publisher matching microsoft and displayname matching lync from c-is-ts-91
            "c-is-ts-91" | Get-InstalledSoftware -DisplayName lync -Publisher microsoft | Format-Table -AutoSize

    .FUNCTIONALITY
        Computers
    #>
        param (
            [Parameter(
                Position = 0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false
            )] # End Paramter
            [ValidateNotNullOrEmpty()]
            [Alias('CN','__SERVER','Server','Computer')]
                [string[]]$ComputerName = $env:computername,

                [string]$DisplayName = $null,

                [string]$Publisher = $null
        ) # End Param

        Begin
        {

            #define uninstall keys to cover 32 and 64 bit operating systems.
            #This will yeild only 32 bit software and double entries on 64 bit systems running 32 bit PowerShell
                $UninstallKeys = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
                    "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

        } # End Begin

        Process
        {

            #Loop through each provided computer.  Provide a label for error handling to continue with the next computer.
            :computerLoop foreach($computer in $computername)
            {

                Try
                {
                    #Attempt to connect to the localmachine hive of the specified computer
                    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)
                } # End Try
                Catch
                {
                    #Skip to the next computer if we can't talk to this one
                    Write-Error "Error:  Could not open LocalMachine hive on $computer`: $_"
                    Write-Verbose "Check Connectivity, permissions, and Remote Registry service for '$computer'"
                    Continue
                } # End Catch

                #Loop through the 32 bit and 64 bit registry keys
                foreach($uninstallKey in $UninstallKeys)
                {

                    Try
                    {
                        #Open the Uninstall key
                            $regkey = $null
                            $regkey = $reg.OpenSubKey($UninstallKey)

                        #If the reg key exists...
                        if($regkey)
                        {

                            #Retrieve an array of strings containing all the subkey names
                                $subkeys = $regkey.GetSubKeyNames()

                            #Open each Subkey and use GetValue Method to return the required values for each
                                foreach($key in $subkeys)
                                {

                                    #Build the full path to the key for this software
                                        $thisKey = $UninstallKey+"\\"+$key

                                    #Open the subkey for this software
                                        $thisSubKey = $null
                                        $thisSubKey=$reg.OpenSubKey($thisKey)

                                    #If the subkey exists
                                    if($thisSubKey){
                                        try
                                        {

                                            #Get the display name.  If this is not empty we know there is information to show
                                                $dispName = $thisSubKey.GetValue("DisplayName")

                                            #Get the publisher name ahead of time to allow filtering using Publisher parameter
                                                $pubName = $thisSubKey.GetValue("Publisher")

                                            #Collect subset of values from the key if there is a displayname
                                            #Filter by displayname and publisher if specified
                                            if( $dispName -and
                                                (-not $DisplayName -or $dispName -match $DisplayName ) -and
                                                (-not $Publisher -or $pubName -match $Publisher )
                                            ) # End if start
                                            {

                                                #Display the output object, compatible with PowerShell 2
                                                New-Object PSObject -Property @{
                                                    ComputerName = $computer
                                                    DisplayName = $dispname
                                                    Publisher = $pubName
                                                    Version = $thisSubKey.GetValue("DisplayVersion")
                                                    UninstallString = $thisSubKey.GetValue("UninstallString")
                                                    InstallDate = $thisSubKey.GetValue("InstallDate")
                                                } | select ComputerName, DisplayName, Publisher, Version, UninstallString, InstallDate
                                            } # End if
                                        } # End try
                                        Catch
                                        {
                                            #Error with one specific subkey, continue to the next
                                            Write-Error "Unknown error: $_"
                                            Continue
                                        }
                                    } # End if
                                } # End Foreach
                        } # End if
                    } # End Try
                    Catch
                    {

                        #Write verbose output if we couldn't open the uninstall key
                        Write-Verbose "Could not open key '$uninstallkey' on computer '$computer': $_"

                        #If we see an access denied message, let the user know and provide details, continue to the next computer
                        if($_ -match "Requested registry access is not allowed"){
                            Write-Error "Registry access to $computer denied.  Check your permissions.  Details: $_"
                            continue computerLoop
                        } # End if

                    } # End Catch
                } # End Foreach
            } # End Foreach

        } # End Process

    } # End Function

    Get-InstalledSoftware -Verbose | Select-Object -Property InstallDate, DisplayName

    } # End else

    pause

    Clear-Host

    } # End 5 List installed applications
    #===================================================================================================================================
    elseif ($Response -eq 6) {

        $computer = Read-Host -Prompt "Enter their Desktops hostname. Example: DesktopComp06"

        $option = Read-Host -Prompt "To add a User enter 1. To Delete a User enter 0"

        if ($option -like '1') {

            Invoke-Command -HideComputerName $computer {

                $user = Read-Host -Prompt "Enter the users SamAccountName. Example: rob.osborne"

                net LOCALGROUP "Remote Desktop Users" /ADD "$User"

                net LOCALGROUP "Remote Desktop Users"

            } # End Invoke-Command

        } # End if

        elseif ($option -like '0') {

            Invoke-Command -HideComputerName $computer {

                $user = Read-Host -Prompt "Enter the users SamAccountName. Example: rob.osborne"

                net LOCALGROUP "Remote Desktop Users" /DELETE "$User"

                net LOCALGROUP "Remote Desktop Users"

            } # End Invoke-Command

         } # End elseif

     pause

     Clear-Host

     } # End 6 Add or delete user to Remote Desktop Users allowed list
    #===================================================================================================================================
    elseif ($Response -eq 7) {

        Invoke-Command -HideComputerName $PrimaryDC -ScriptBlock {

            Import-Module ActiveDirectory

            do {

                $group = Read-Host -Prompt "What group are you looking for Example: Domain Admins"

                $GroupExists = Get-AdGroup -Filter * | Where-Object -Property Name -Like $group

            } # End do
            while (!($GroupExists))

            Write-Host "Group has been verified to exist."

            Get-ADUser -Filter * -Properties DisplayName,memberof | ForEach-Object { New-Object PSObject -Property @{

                UserName = $_.DisplayName

                Groups = ($_.memberof | Get-ADGroup | Where-Object {$_.GroupCategory -eq "Security"} | Select-Object -ExpandProperty Name) -join ","

            } # End Properties

            } | Select-Object UserName,Groups | Where-Object -Property Groups -like *$group* | Format-Table -Property UserName

         } # End Invoke

    pause

    Clear-Host

    } # End 7 List all members of a group
    #===================================================================================================================================
    elseif ($Response -eq 8) {

        $computadora = Read-Host -Prompt 'What is the computers hostname? Example: DesktopComp08'

        quser /server:$computadora

        $session = Read-Host -Prompt 'What is the Session ID of the user you want logged out? Example: 2'

        try {

            Invoke-RDUserLogoff -HostServer $computadora -UnifiedSessionId $session -Force -Credential (Get-Credential -Message 'Use Admin Credentials')

        } # End Try

        catch {

            $Error[0]

            Write-Host 'Invoke-RdUserLogoff cmdlet failed. Attempting to use Get-WmiObject to log user off.'

            (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computadora).Win32Shutdown(4)

        } # End Catch

    pause

    Clear-Host

    } # End 8 Log User off a Device
    #====================================================================================================================================

    elseif ($Response -eq 9) {

        $machine = Read-Host -Prompt "Look up the last reboot time for which device? Example: DesktopComp09"

        try {

            Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $machine | Select-Object -Property csname, lastbootuptime

        } # End Try

        catch {

            Write-Warning "Error issuing Get-CimInstance on device."

            $Error[0]

        } # End Catch

    pause

    Clear-Host

    } # End 9 Last Reboot Time
    #====================================================================================================================================

    elseif ($Response -eq 10) {

        $user = Read-Host -Prompt 'What is the users name Example: Contoso\rob.osborne'

        $objUser = New-Object System.Security.Principal.NTAccount($user)

        $objSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])

        if (!($objSID -eq $null)) {

            Write-Host "Resolved user's sid: " $objSID.Value

            } # End if

        else {

            Write-Host "SID Lookup failed."

        } # End Else

    pause

    Clear-Host

    } # End 10 Resolve Username to SID
    #=====================================================================================================================================

    elseif ($Response -eq 11) {

        $CertLookup = Read-Host 'What device is the certificate on? Example: DesktopComp13'

        Invoke-Command -HideComputerName $CertLookup -ScriptBlock {

            $cert = Read-Host -Prompt 'Enter the Certificates Thumbrpint. Example: 1ffbe67543c5a6fffe4d60b8e661671950cdacbd'

            Write-Host 'Checking Local Computer'

            Get-ChildItem -Path cert:\LocalMachine\My -Recurse | Where-Object -Property Thumbprint -like $cert | Select-Object -Property *

            Write-Host 'Checking Currnet User'

            Get-ChildItem -Path Cert:\CurrentUser\My -Recurse | Where-Object -Property Thumbprint -like $cert | Select-Object -Property *

        } # End Invoke-Command

    pause

    Clear-Host

    } # End 11 Lookup up certificate by its thumbprint
    #=====================================================================================================================================

    elseif ($Response -eq 12) {

        Invoke-Command -HideComputerName $PrimaryDC -ScriptBlock {

            Import-Module ActiveDirectory

            $Old = Read-Host -Prompt 'What is the users CURRENT first name? Example: Bill'

            $First = Read-Host -Prompt 'What is the users NEW first name? Example: Joe'

            $Last = Read-Host -Prompt 'What is the users Last name? Example: Smith'

            Write-Host "User information is being updated in Active Directory"

            Try {

                $User = Get-ADUser -Identity ("$Old.$Last") -Properties *

                $User | Set-ADUser -Identity "$First $Last" -DisplayName "$First $Last" -GivenName $First -Surname $Last -EmailAddress "$First.$Last@$Domain" -SamAccountName "$First.$Last" -UserPrincipalName "$First.$Last@$Domain"

            } # End try

            Catch {

                Read-Host "An error as occured. Please try again and ensure all the information was entered correctly"

            } # End Catch

            Write-Host "Allowing Synchronization of user in Azure Environment"

            Connect-MsolService

            $Statement = Get-MsolDirSyncFeatures -Feature SynchronizeUpnForManagedUsers

            if (!$Statement) {

                Set-MsolDirSyncFeature -Feature SynchronizeUpnForManagedUsers -Enable $true

                } # End if

            # Sync AD and Azure

            Write-Host "Syncing Azure AD with Active Directory changes"

            Invoke-Command -HideComputerName $AzureAdServer -ScriptBlock {

                Start-AdSyncSyncCycle -PolicyType Initial

                 } # End Invoke

        } # End ScriptBlock

    pause

    Clear-Host

    } # End 12 Change an existing users first name
    #=====================================================================================================================================

    elseif ($Response -eq 13) {

        Invoke-Command -HideComputerName $PrimaryDC -ScriptBlock {

            Import-Module ActiveDirectory

            $First = Read-Host -Prompt 'What is the users first name? Example: Joe'

            $Old = Read-Host -Prompt 'What is the users OLD last name? Example: Johnson'

            $Last = Read-Host -Prompt 'What is the users NEW last name? Example: Smith'

            Write-Host "User information is being updated in Active Directory"

            Try {

                $User = Get-ADUser -Identity ("$First.$Old") -Properties *

                $User | Set-ADUser -DisplayName "$First $Last" -GivenName $First -Surname $Last -EmailAddress "$First.$Last@$Domain" -SamAccountName "$First.$Last" -UserPrincipalName "$First.$Last@$Domain"

            } # End try

            Catch {

                Read-Host "An error as occured. Please try again and ensure all the information was entered correctly"

            } # End Catch

            Write-Host "Allowing Synchronization of user in Azure Environment"

            Connect-MsolService

            $Statement = Get-MsolDirSyncFeatures -Feature SynchronizeUpnForManagedUsers

            if (!$Statement) {

                Set-MsolDirSyncFeature -Feature SynchronizeUpnForManagedUsers -Enable $true

                }# End If Not

            # Sync AD and Azure

            Write-Host "Syncing Azure AD with Active Directory changes"

            Invoke-Command -HideComputerName $AzureAdServer -ScriptBlock {

                Start-AdSyncSyncCycle -PolicyType Initial

            } # End Invoke

            # Change H Drive Folder name

#            Write-Host "Currently Changing H Drive information" # This will depend on your environment. If changing a users name requires a folder name to change edit this

#            $newdrivename = $first[0]+$last

#            $olddrivename = $first[0]+$old

#            Rename-Item -Path "\\networkshare\users$\$olddrivename" -NewName { $newdrivename } -Force

        } # End Invoke-Command

    pause

    Clear-Host

    } # End 13 Change an existing users last name
    #=====================================================================================================================================

    elseif ($Response -eq 14) {

        Invoke-Command -HideComputerName $PrimaryDC -ScriptBlock {

            $GPcomputer = Read-Host "Enter Computer Hostname (Example: DesktopComp18) to gpupdate or type all to gpupdate everything."

            if ($GPcomputer -like 'all') {

                $devices = Get-ADComputer -Filter * | Select-Object Name

                foreach ($Device in $Devices) {

                    try {

                        Invoke-GpUpdate $device -Force

                        } # End Try

                    catch {

                        Invoke-Command -HideComputerName $device -ScriptBlock {

                            gpupdate /force

                            } -InDisconnectedSession # End Invoke

                        } # End Catch

                   } # End ForEach

            } # End If

             else {

                try {

                    Invoke-Command -HideComputerName $GPcomputer -ScriptBlock {

                        gpupdate /force

                        } # End Invoke

                    } # End try

                 catch {

                    Invoke-GPUpdate $GPcomputer -Force

                    } # End Catch

             } # End Else

             } # End Invoke

    pause

    Clear-Host

     } # End 14 Group Policy Update
    #=====================================================================================================================================

    elseif ($Response -eq 15) {

        <#
        .Synopsis
            Update-ADSync was created to simplify the command to sync Azure and AD

        .DESCRIPTION
            Update-ADSync is used to easily sync Azure AD with on premise AD

        .EXAMPLE
            Update-ADSync

        .EXAMPLE
            Update-ADSync -Verbose
        #>

        Function Update-ADsync {

        [CmdletBinding()]

        param([switch]$Elevated)

            function Test-Admin {
            $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
            $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

            } # End Test-Admin Function

        if ((Test-Admin) -eq $false)  {

            if ($elevated) {

                # could not elevate, quit

            } # End if

            else {

                Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))

            } # End else

            exit

        } # End if

            if ("$env:COMPUTERNAME" -like $AzureAdServer) {

                        try {

                            Import-Module ADSync

                            Start-ADSyncSyncCycle -PolicyType Initial

                        } # End try

                        catch {

                             Write-Verbose 'AD Sync is already in progress. Current sync needs to complete before it can be run again.'

                        } # End Catch

            } # End if

            else {

                try {

                    Invoke-Command -ComputerName $AzureAdServer -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Initial }

                } # End try

                catch {

                    Write-Verbose 'AD Sync is already in progress. Current sync needs to complete before it can be run again.'

                } # End Catch

            } # End Else

        } # End Function

        Update-ADsync -Verbose

    pause

    Clear-Host

    } # End 15 Sync AD and Azure
    #=====================================================================================================================================

    elseif ($Response -eq 16) {

        <#
        .Synopsis
            Find-File is a cmdlet created to help a user find a file they only remeber part of the name of.
            It can also be used to find the location of a file where the name is remember but the location is not.
            This cmdlet was designed for users. As such no switches need to be defined. Running the cmdlet will prompt the user for input.

        .DESCRIPTION
            This cmdlet searches the C: Drive for a rough file name and returns its location.
            If more than one file are found, more than one location will be returned.

        .AUTHOR
            Written by Rob Osborne - rosborne@osbornepro.com
            Alias: tobor

        .EXAMPLE
           Find-File

        .EXAMPLE
           Find-File -Verbose

        #>

        Function Find-File {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True,
                        ValueFromPipeline=$True,
                        ValueFromPipelineByPropertyName=$True,
                        HelpMessage="The File's Name. `n Use * anywhere you are unsure of what comes next.`n * represents anything. `n Example: *USA*.txt `n If you see this message, you will need to press enter after being prompted to define a second file name. `n This will begin your search. `n Adding another file to search for will not work.")] # End Parameter
            [string[]]$FileName
        ) # End param

        Write-Verbose "Begining Search. Please Wait..."

        $PathResults = Get-ChildItem -Path 'C:\' -Filter "$FileName" -Recurse -ErrorAction SilentlyContinue -Force

        if ($PathResults) {

            foreach ($Result in $PathResults) {

                $properties = @{
                        File = $Result
                        Directory = $Result.DirectoryName
                        FullPath = $Result.FullName
                        LastAccessed = $Result.LastAccessTime
                        LastEdited = $Result.LastWriteTime
                        Created = $Result.CreationTime
                } # End Properties

            $obj = New-Object -TypeName PSCustomObject -Property $properties

            Write-Output $obj

            } # End ForEach

        } # End if

        else {

            Write-Warning "No file found by that name on the C: Drive. `n If you feel you received this warning in error, `n 1.) Ensure you added a file extension `n 2.) Try to be less specific by using *. `n 3.) Only add one file name to search for"

        } # End Else


        } # End Function

    Find-File -Verbose

    pause

    Clear-Host

    } # End 16 Find a files location
    #=====================================================================================================================================

    elseif ($Response -eq 17) {

        $hibernator = Read-Host 'What device needs hibernating disabled? Exmaple: DesktopComp01'

        Invoke-Command -HideComputerName $hibernator -ScriptBlock {

            POWERCFG -H off

            } # End Invoke

        Write-Host "Hibernation disabled on $hibernator"

    pause

    Clear-Host

    } # End 17 Disable Hibernate
    #=====================================================================================================================================

    elseif ($Response -eq 18) {

        $item = Read-Host 'What is the location of the file or folder you want to add permissions to? Example: \\networkshare\share$\Rob\thisone.xlsx'

        $person = Read-Host 'What is the SamAccountName of the person you want to add? Example: rob.osborne'

        $Acl = Get-Acl -Path $item

        $AccessRights = New-Object  system.security.accesscontrol.filesystemaccessrule("$person","FullControl","Allow")

        $Acl.SetAccessRule($AccessRights)

        Set-Acl -Path $item $Acl

    pause

    Clear-Host

    } # End 18 Add user to permissions on a file or folder
    #=====================================================================================================================================

    elseif ($Response -eq 19) {

        Invoke-Command -HideComputerName $PrimaryDC -ScriptBlock {

            Import-Module ActiveDirectory

            do {

                $FullName = Read-Host 'What is the users full name? Example: Joe McLovin'

                $AccountDetails = Get-AdUser -Filter {Name -eq $FullName}  -Properties Title

            } # End Do

            while (!($AccountDetails))

            $CurrentTitle = $AccountDetails.Title

            $NewTitle = Read-Host "Current title is $CurrentTitle `nWhat is their new job title?"

            $NewDepartment = Read-Host "What department are they in?"

            try {

                $AccountDetails | Set-AdUser -Title $NewTitle -Department $NewDepartment

            } # End Try

            catch {

                Write-Warning 'There was an issue changing the title.'

                $Error[0]

            } # End Catch

        } # End Script Block

        Clear-Host

    } # End 19 Change Users Title and Department
    #=====================================================================================================================================

    } # End Do

    while ($sw.elapsed -lt $timeout) {write-host "Timed out"} # End While

} # End Function

Get-HelpDesk -Verbose
