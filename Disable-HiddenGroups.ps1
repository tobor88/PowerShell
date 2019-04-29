<#
.Synopsis
    Disable-HiddenGroups changes the switch -HiddenFromExchangeClientsEnabled to false for all Office365 Groups created in Microsoft Teams
    This cmdlet was designed for users. As such no switches need to be defined. Running the cmdlet will not prompt the user for input.
    The user will need to be granted permissions to change this setting and also be the groups owner. Or you can jsut do it for them.

.DESCRIPTION
    A recent Microsoft Office Update has changed -HiddenFromExchangeClientsEnabled from default false to default true. 
    This cmdlet can be uesd to change -HiddenFromExchangeClientsEnabled to false for all newly created groups
    Written by Rob Osborne - rosborne@osbornepro.com 
    Alias: tobor

.EXAMPLE
   Disable-HiddenGroups 

.EXAMPLE
   Disable-HiddenGroups -Verbose

#>

Function Disable-HiddenGroups {
    [CmdletBinding()]
        Param()

    Begin {

        if (Get-PSSession | Where-Object -Property ConfigurationName -like 'Microsoft.Exchange') {

            Remove-PSSession -Session *

            $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $cred -Authentication Basic -AllowRedirection
 
            Write-Verbose 'Importing Exchange Online Cmdlets'

            Import-PSSession $Session

            Clear-Host 

        } # End Try

        else {

            $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $cred -Authentication Basic -AllowRedirection
 
            Write-Verbose 'Importing Exchange Online Cmdlets'

            Import-PSSession $Session

            Clear-Host
            
        } # End Else 

    } # End Begin

    Process {
        
        try {

            Write-Verbose "Obtaining list of all Office365 Team Display Names `n Please wait......."

            $UnifiedGroup = Get-UnifiedGroup | Select-Object -Property DisplayName
   
        } # End Try

        catch {

            Write-Warning "Issue running the command. Ensure you are connected to the internet. `nVerify you have permission to execute Get-UnifiedGroup cmdlet. `nVerify you are entering your password correctly."

            $Error[0]

        } # End Catch

    } # End Process

    End { 

            Write-Verbose "Successfully found your Office365 Groups. `nIssuing Command to prevent hiding Office 365 groups from Outlook."

            foreach ($G in $Group) {

                Set-UnifiedGroup -Identity $G.Name -HiddenFromExchangeClientsEnabled:$False -ErrorAction SilentlyContinue

                Write-Verbose "$G `nCompleted"

            } # End Foreach

    } # End Finally

} # End Function

Disable-HiddenGroups -Verbose

Write-Host "Success! Press Enter to Exit.`n "

pause