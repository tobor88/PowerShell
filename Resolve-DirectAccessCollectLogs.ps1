<#
.SYNOPSIS
This cmdlet is used to edit the Windows Registry on a device where clicking the "Collect" button for DirectAccess
does not build a log or bring up an email prompt for sending troubleshooting info to IT Admins aka you.


.DESCRIPTION
ISSUE:
The reason behind this bug is that starting with the creators update (Windows 10 1703) a new feature is introduced.
The feature is the split feature that allowed something like SVCHOST to run independent process for each service.
So the one in question here is the Networking connectivity Assist “NCASVC” that runs under the NetSVC SVCHOST.
The “NCASVC” will split into its own SVCHOST and log collection fails. In addition the log collection process is
series of powershell commands that runs on the machine to collect logs. This will fail to launch due to missing the
privilege “SeAssignPrimaryTokenPrivilege” on this splitted new process.

RESOLUTON:
To fix the issue we need to stop/disable this split process or grant the needed privilege.


.PARAMETER Restart
Defining the -Restart parameter will prompt you to restart the device after making the registry change.

.PARAMETER PermissionChange
Defining this parameter will add the SeAssignPrimaryTokenPrivilege to the NcaSvc process. It will also
not disable split process.

.PARAMETER DisableSplitProcess
Defining this parameter will disable split process. This will also not give NcaSvc SeAssignPrimaryTokenPrivilege
permissions.


.EXAMPLE
C:\PS> Resolve-DirectAccessCollectLogs -PermissionChange
# This example assigns the NcaSvc service SeAssignPrimaryTokenPrivilege privileges.

.EXAMPLE
C:\PS> Resolve-DirectAccessCollectLogs -DisableSplitProcess -Restart
# This example disables split processes and attempts to restart the device to apply the registry changes.


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


.INPUTS
None
You cannot pipe input to this cmdlet.


.OUTPUTS
System.Management.Automation.PSCustomObject
New-ItemProperty returns a custom object that contains the new property.
#>
Function Resolve-DirectAccessCollectLogs {
    [CmdletBinding()]
        param(
            [Parameter(
                ParameterSetName="Permission",
                Mandatory=$True)]  # End Parameter
            [Switch][Bool]$PermissionChange,

            [Parameter(
                ParameterSetName="Split",
                Mandatory=$True)]  # End Parameter
            [Switch][Bool]$DisableSplitProcess,

            [Parameter(
                Mandatory=$False)]  # End Parameter
            [Switch][Bool]$Restart
        )  # End param

$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NcaSvc"
$DWORDName = "SvcHostSplitDisable"
$Permission = "SeAssignPrimaryTokenPrivilege"

Switch ($PSBoundParameters.Keys) {
    'PermissionChange' {

        If (Test-Path -Path "$RegistryPath") {

            Write-Verbose "[*] Enabling the registry value $DWORDName for $RegistryPath"
            New-ItemProperty -Path "$RegistryPath" -Name $DWORDName -PropertyType "DWORD" -Value 1

        }  # End If
        Else {

            Throw "[x] Registry value $RegistryPath does not exist. This location should exist already."

        }  # End Else

    }  # End PermissionChange
    'DisableSplitProcess' {

        If (Test-Path -Path "$RegistryPath") {

            Write-Verbose "[*] Adding $Permission privileges to NcaSvc service"
            New-ItemProperty -Path "$RegistryPath" -Name "RequiredPrivileges" -Value

        }  # End If
        Else {

            Throw "[x] Registry value $RegistryPath does not exist. This location should exist already."

        }  # End Else

    }  # End DisableSplitProcess

}  # End Switch

If ($PsBoundParameters.Keys.Value -contains "Restart") {

    Restart-Computer -Confirm

}  # End If

}  # End Function Resolve-DirectAccessCollectLogs
