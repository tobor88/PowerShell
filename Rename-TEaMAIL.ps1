<#
.SYNOPSIS
Rename-Team changes the email address of a Team. This is done because when Users Rename their Teams and they expect the email will be changed as well.
This cmdlet was designed for users. Current group name and new email address will need to be entered by the user after the cmdlet is run.
The user may need to be granted permissions to change this setting and also be the groups owner. Or you can just do it for them.

.DESCRIPTION
Renaming a Team in Office365 does not automatically change the email address.
This cmdlet is used to allow users to rename their Office365/Team email.


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


.EXAMPLE
  Rename-Team
#>

Function Rename-Team {
    [CmdletBinding()]
       Param() # End Param

    BEGIN {

        If (Get-PSSession | Where-Object -Property ConfigurationName -like 'Microsoft.Exchange') {

            Remove-PSSession -Session *

            Try {

                $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential (Get-Credential) -Authentication Basic -AllowRedirection
                Write-Verbose 'Importing Exchange Online Cmdlets'
                Import-PSSession $Session

            } # End Try
            Catch {

                Write-Warning 'There was an issue connecting to Office365 online. Stopping script...'

            } # End Catch

            Clear-Host

        } # End Try
        Else {

            Try {

                $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential (Get-Credential) -Authentication Basic -AllowRedirection
                Write-Verbose 'Importing Exchange Online Cmdlets'
                Import-PSSession $Session

            } # End Try
            Catch {

                Write-Warning 'There was an issue connecting to Office365 online. Stopping script...'

            } # End Catch

            Clear-Host

        } # End Else

    } # End BEGIN
    PROCESS {

        Do {

            $Group = Read-Host "What is the current name of the Team you want to change the email address of?"

            $Name = Get-UnifiedGroup -Identity $Group -ErrorAction SilentlyContinue

        } # End Do
        While (!($Name))

        Write-Host "Successfully selected a Team Name."
        Do {

            $NewEmail = Read-Host "What should the new email address be?"

            If ($NewEmail -like "*@contoso.com") {

                $TestEmail = 'True'

            }  # End If
            Else {

                $TestEmail = 'False'

            }  # End Else

        } # End Do
        While ($TestEmail -like 'False')

        Write-Host "Successfully selected a contoso.com email address. Changing email address for $Group to $NewEmail"

    } # End PROCESS
    END {

        Try {

            Set-UnifiedGroup -Identity $Group -PrimarySmtpAddress $NewEmail
            Set-UnifiedGroup -Identity $Group -EmailAddresses: @{add="SMTP:$NewEmail"}
            Get-UnifiedGroup -Identity $Group | Select-Object -Property * | Format-List

        } # End try
        Catch {

            Write-Warning "In theory this should not have errored. Way to go. Contact Rob."

        } # End Catch

    } # End End

} # End Function

Do {

    Rename-Team -Verbose
    $Continue = Read-Host "If you would like to change another Team email address type Y and press Enter.`n If you would like to exit just press Enter."

} # Do
while ($Continue -like 'Y')
