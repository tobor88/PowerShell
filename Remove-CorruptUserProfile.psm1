Function Remove-CorruptUserProfile
{
        [CmdletBinding()]
        param(
            [Parameter(Mandatory =$True,
                Position=0,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter the users SamAccountName. Example: rob.osborne")] # End Parameter
            [string[]]$SamAccountName
        ) # End param

# The below variable is used at line 89
$Domain = Read-Host "What domain is the user a part of? Example: OsbornePro"

# PART ONE
    Function Copy-BackupProfile
    {
        [CmdletBinding()]
        param(
            [Parameter(
                Mandatory = $True,
                Position = 0,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage = "Enter a SamAccountName for the user profile. Example: rob.osborne"
            )] # End Parameter
        [string[]]$SamAccountName) # End param

        If (Test-Path "C:\Users\$SamAccountName")
        {

            Write-Verbose "$SamAccountName folder has been found. Renaming profile folder to $SamAccountName.old..."

            Rename-Item -Path "C:\Users\$SamAccountName" -NewName "$SamAccountName.old" -Force -ErrorAction "SilentlyContinue" | Out-Null

            Write-Verbose "Renaming AppData folder to prevent any corruptions from being moved to the new profile."

            Rename-Item -Path "C:\Users\$SamAccountName.old\AppData" -Destination "C:\Users\$SamAccountName.old\OLDAppData" -Force -ErrorAction "SilentlyContinue" | Out-Null

            Write-Host "If the user uses sticky notes they are located here: `n`tC:\Users\$SamAccountName\AppData\Roaming\Microsoft\Sticky Notes " -ForegroundColor "Green"

        } # End If
        Else
        {

            Write-Warning "No user directory found at C:\Users\$SamAccountName Ending script."

            break

        } # End Else

    }  # End Function Copy-BackupProfile

    Copy-BackupProfile -SamAccountName $SamAccountName -Verbose


# PART TWO
    Function Get-UserSid {
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

    $SID = Get-UserSid -SamAccountName "$Domain\$SamAccountName" -Verbose


# PART THREE
    Function Remove-CorruptUserProfileRegistryItem
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $True,
                        Position = 0,
                        ValueFromPipeline=$True,
                        ValueFromPipelineByPropertyName=$True,
                        HelpMessage="Enter the users SamAccountName. Example: rob.osborne")] # End Parameter
        [string[]]$SID) # End param

        $ProfileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$SID"

        $ProfileGuidPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileGUID"

        If (Test-Path -Path $ProfileListPath)
        {

            $CorruptedUser = (Get-ItemProperty -Path $ProfileListPath -Name "ProfileImagePath" | Select-Object -ExpandProperty "ProfileImagePath").Replace('C:\Users\','')

            Read-Host "Is $CorruptedUser the user with a corrupted profile? Press Ctrl+C to cancel and Enter to continue deleting the profile."

            Remove-Item -Path $ProfileListPath -Recurse -Force

        } # End If
        Else
        {

            Write-Warning "$ProfileListPath location not found."

        } # End Else

        If (Test-Path $ProfileGuidPath)
        {

            $GUIDs = Get-ChildItem $ProfileGuidPath | Select-Object -ExpandProperty "PsChildName"

            ForEach ($GUID in $GUIDs)
            {

                $SidGuid = Get-ItemProperty -Path "$ProfileGUIDPath\$GUID" | Select-Object -ExpandProperty "SidString"

                If ($SidGuid -eq $SID)
                {

                    Remove-Item -Path "$ProfileGuidPath\$GUID" -Recurse -Force

                } # End If

            } # End ForEach

        } # End If
        Else
        {

            Write-Warning "$ProfileGuidPath location not found."

        } # End Else

    } # End Function Remove-CorruptUserProfile

    Remove-CorruptUserProfileRegistryItem -SID $SID -Verbose

    Write-Host "Press Enter to Restart Computer now or press Ctrl+C to complete the rest of this task later." -ForegroundColor "Red"

    pause

    Restart-Computer -Force

} # End Function Remove-CorruptedUserProfile
