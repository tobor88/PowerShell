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

            Write-Verbose "$SamAccountName folder has been found. Creating a backup of their profile..."

            Copy-Item -Path "C:\Users\$SamAccountName" -Destination "C:\Users\$SamAccountName.old" -Recurse -Force -ErrorAction "SilentlyContinue" | Out-Null

            Write-Verbose "Deleting AppData folder to prevent any corruptions from being moved to the new profile."

            Remove-Item -Path "C:\Users\$SamAccountName.old\AppData" -Recurse -Force

        } # End If
        Else
        {

            Write-Warning "No user directory found at C:\Users\$SamAccountName Ending script."

        } # End Else

    }  # End Function Copy-BackupProfile

    Copy-BackupProfile -SamAccountName $SamAccount -Verbose


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

            $objSID.Value

        } # End If
        Else
        {

            Write-Warning "SID Lookup failed."

        } # End Else

    } # End Function Get-UserSid

    $SID = Get-UserSid -SamAccountName "OsbornePro\$SamAccount" -Verbose

    Function Remove-CorruptUserProfileRegistryItem
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = True,
                        Position = 0
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

} # End Function Remove-CorruptedUserProfile
