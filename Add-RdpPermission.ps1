<#
.SYNOPSIS
Add-RdpPermission is a cmdlet that is used for adding RDP permissions onto a remote computer for a Domain user.


.DESCRIPTION
Adds RDP access on a computer for a defined Domain user.


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
Add-RdpPermission -ComputerName $ComputerName -AdUser $SamAccountUserName

.EXAMPLE
Add-RdpPermission -ComputerName $ComputerName -AdUser $SamAccountUserName -Verbose
#>
Function Add-RdpPermission {
    [CmdletBinding()]
        param(
        [Parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="The Remote Computer's Hostname. `n Example: Desktop01 `n`n If you see this message, you will need to enter the remote computers name you want to add RDP permissions too.")] # End Parameter
            [ValidateNotNullorEmpty()]
        [String[]]$ComputerName, # End Paramater

        [Parameter(Mandatory=$True,
                Position=1,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="The Active Directory User's SamAccountName. `n Example: firstname.lastname `n`n If you see this message, you will need to enter the domain users SamAccountName you want to add RDP permissions too.")] # End Parameter
            [ValidateNotNullorEmpty()]
        [String[]]$AdUser # End Parameter

) # End param

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {

                       net LOCALGROUP "Remote Desktop Users" /ADD "$AdUser"
                       net LOCALGROUP "Remote Desktop Users"

                       Write-Host "If you have received an error message you either will need to run the command as an adminstrator or the user is already a member of allowed RDP users."
                       Read-Host "Press Enter to Exit"

    } # End Invoke-Command

} # End Function
