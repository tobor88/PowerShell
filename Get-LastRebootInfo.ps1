<#
.SYNOPSIS
This cmdlet is used to obtain reboot information on a local or remote device


.DESCRIPTION
This works by querying the Event Log for Event ID 1074 and returns the pertinant information from it


.PARAMETER ComputerName
Defines the computer(s) you wish to obtain the last reboot information on


.EXAMPLE
Get-LastRebootInfo
# This example obtains information on the last reboots from the local device

.EXAMPLE
Get-LastRebootInfo -ComputerName 'DC01.contoso.com', '10.0.0.1'
# This example obtains information on the last reboots from the remote devices DC01.contoso.com and 10.0.0.1


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.INPUTS
System.String System.Array


.OUTPUTS
System.Array


.LINK
https://osbornepro.com
https://btpssecpack.osbornepro.com
https://writeups.osbornepro.com
https://github.com/OsbornePro
https://gitlab.com/tobor88
https://www.powershellgallery.com/profiles/tobor
https://www.hackthebox.eu/profile/52286
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges
#>
Function Get-LastRebootInfo {
    [CmdletBinding()]
        param(
            [Parameter(
                Position=0,
                Mandatory=$False,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="`n[H] Define the FQDN, Hostname, or IP address of a device. Separate multiple values with a comma. `n[E] EXAMPLE: 'DC01.contoso.com','10.10.10.10'")]  # End Parameter
        [Alias('cn')]
        [String[]]$ComputerName="$env:COMPUTERNAME"
        )  # End param


    $Results = [System.Collections.ArrayList]::New()
    ForEach ($C in $ComputerName) {

        $Results += Invoke-Command -HideComputerName "$C.$env:USERDNSDOMAIN" -UseSSL -ScriptBlock {Get-WinEvent -FilterHashtable @{logname='System'; id=1074} | `
        ForEach-Object {

            $Obj = New-Object -TypeName PSObject | Select-Object -Property Date, User, Action, Process, Reason, ReasonCode, Comment
            $Obj.Date = $_.TimeCreated
            $Obj.User = $_.Properties[6].Value
            $Obj.Process = $_.Properties[0].Value
            $Obj.Action = $_.Properties[4].Value
            $Obj.Reason = $_.Properties[2].Value
            $Obj.ReasonCode = $_.Properties[3].Value
            $Obj.Comment = $_.Properties[5].Value
            $Obj

        } | Select-Object Date, Action, Reason, User

        }  # End ForEach-Object

}  # End ForEach

    $Results

}  # End Function
