<#
.SYNOPSIS
Disable-HiddenGroups changes the switch -HiddenFromExchangeClientsEnabled to false for all Office365 Groups created in Microsoft Teams
This cmdlet was designed for users. As such no switches need to be defined. Running the cmdlet will not prompt the user for input.
The user will need to be granted permissions to change this setting and also be the groups owner. Or you can jsut do it for them.


.DESCRIPTION
A recent Microsoft Office Update has changed -HiddenFromExchangeClientsEnabled from default false to default true.
This cmdlet can be uesd to change -HiddenFromExchangeClientsEnabled to false for all newly created groups


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
Disable-HiddenGroups
#>

Function Disable-HiddenGroups {
    [CmdletBinding()]
        Param()

    BEGIN {

        If (Get-PSSession | Where-Object -Property ConfigurationName -like 'Microsoft.Exchange') {

            Remove-PSSession -Session *

        } # End if

        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $cred -Authentication Basic -AllowRedirection

        Write-Verbose 'Importing Exchange Online Cmdlets'
        Import-PSSession $Session
        Clear-Host

    } # End BEGIN

    PROCESS {

        Try {

            Write-Verbose "Obtaining list of all Office365 Team Display Names `n Please wait......."
            $UnifiedGroup = Get-UnifiedGroup | Select-Object -Property DisplayName

        } # End Try
        Catch {

            Write-Warning "Issue running the command. Ensure you are connected to the internet. `nVerify you have permission to execute Get-UnifiedGroup cmdlet. `nVerify you are entering your password correctly."
            $Error[0]

        } # End Catch

    } # End PROCESS

    END {

        Write-Verbose "Successfully found your Office365 Groups. `nIssuing Command to prevent hiding Office 365 groups from Outlook."
        ForEach ($G in $Group) {

            Set-UnifiedGroup -Identity $G.Name -HiddenFromExchangeClientsEnabled:$False -ErrorAction SilentlyContinue
            Write-Verbose "$G `nCompleted"

        } # End Foreach

    } # End END

} # End Function Disable-HiddenGroups
