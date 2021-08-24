# This script can be used to map network shares automatically by having the task run on startup. It maps drive shares based on group memberships
$Domain = $env:USERDNSDOMAIN.Split('.')
<#
.SYNOPSIS
This cmdlet is for translating an SID to a username or a username to an SID.


.PARAMETER Username
If the username parameter value is specified it this cmdlet will result in the SID value of the user.

.PARAMETER SID
If the SID parameter value is specified this cmdlet will result in the username value associated with the SID.


.EXAMPLE
C:\PS> $Pipe = New-Object PSObject -Property @{SID='S-1-5-21-2860287465-2011404039-792856344-500'}
C:\PS> $Pipe | Convert-SID

.EXAMPLE
C:\PS> Convert-SID -Username 'j.smith'
C:\PS> Convert-SID -Username j.smith@domain.com

.EXAMPLE
C:\PS> Convert-SID -SID S-1-5-21-2860287465-2011404039-792856344-500
C:\PS> Convert-SID -SID 'S-1-5-21-2860287465-2011404039-792856344-500'


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
System.Array of Usernames or SIDs can be piped to this cmdlet based on property value name.


.OUTPUTS
System.Management.Automation.PSCustomObject

#>
Function Convert-SID {
    [CmdletBinding(DefaultParameterSetName = 'Username')]
        param(
            [Parameter(
                ParameterSetName='Username',
                Position=0,
                Mandatory=$True,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True)]  # End Parameter
            [ValidateNotNullOrEmpty()]
            [Alias('User','SamAccountName')]
            [String[]]$Username,

            [Parameter(
                ParameterSetName='SID',
                Position=0,
                Mandatory=$True,
                ValueFromPipeLine=$True,
                ValueFromPipeLineByPropertyName=$True)]  # End Parameter
            [ValidateNotNullOrEmpty()]
            [ValidatePattern('S-\d-(?:\d+-){1,14}\d+')]
            [String[]]$SID)  # End param


BEGIN {

    [array]$Obj = @()

    Write-Verbose "[*] Obtaining username and SID information for defined value"

}  # End BEGIN
PROCESS {

    For ($i = 0; $i -lt (Get-Variable -Name ($PSCmdlet.ParameterSetName) -ValueOnly).Count; $i++) {

        $Values = Get-Variable -Name ($PSCmdlet.ParameterSetName) -ValueOnly
        New-Variable -Name ArrayItem -Value ($Values[$i])
        Switch ($PSCmdlet.ParameterSetName) {

            SID {$ObjSID = New-Object -TypeName System.Security.Principal.SecurityIdentifier($ArrayItem); $ObjUser = $ObjSID.Translate([System.Security.Principal.NTAccount])}
            Username {$ObjUser = New-Object -TypeName System.Security.Principal.NTAccount($ArrayItem); $ObjSID = $ObjUser.Translate([System.Security.Principal.SecurityIdentifier])}

        }  # End Switch

        $Obj += New-Object -TypeName "PSObject" -Property @{
            Username = $ObjUser.Value
            SID = $ObjSID.Value
        }   # End Property

        Remove-Variable -Name ArrayItem

    }  # End For

}  # End PROCESS
END {

    Write-Output $Obj

}  # End END

}  # End Function Convert-SID


$First,$Last = ($env:USERNAME).Split(".")
$Drivename = $First[0]+$Last
$Token = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$GroupSIDs = $Token.Groups
$GroupNames = @()
ForEach ($G in $GroupSIDs) {

    $GroupNames += (Convert-SID -SID $G).Username.Replace('$DOMAIN\','')

}  # End ForEach


$First,$Last = ($env:USERNAME).Split(".")
$DriveName = $First[0]+$Last
# DriveName is for mapping personal drives using the First Name Initial + Lastname naming context. Change to whatever you like

$DriveHashTable = @{}

$DriveHashTable.BullsShare = @()
$DriveHashTable.BullsShare += "C"
$DriveHashTable.BullsShare += "Bulls"
$DriveHashTable.BullsShare += "\\files.$env:USERDNSDOMAIN\Bulls$"
$DriveHashTable.BullsShare += "\\files\Bulls$"

$DriveHashTable.KnickShare = @()
$DriveHashTable.KnickShare += "N"
$DriveHashTable.KnickShare += "Knicks"
$DriveHashTable.KnickShare += "\\files.$env:USERDNSDOMAIN\Knicks$\$Drivename"
$DriveHashTable.KnickShare += "\\files\Knicks$\$Drivename"

$DriveHashTable.UserShare = @()
$DriveHashTable.UserShare += "U"
$DriveHashTable.UserShare += "Users Share Drive"
$DriveHashTable.UserShare += "\\files.$env:USERDNSDOMAIN\MyShare\$DriveName"
$DriveHashTable.UserShare += "\\files\MyShare\DriveName"

ForEach ($Drive in $DriveHashTable.Keys)
{

    $DrivesLetter = $DriveHashTable.$Drive.Item(0)
    $DrivesGroup = $DriveHashTable.$Drive.Item(1)
    $DriveLocation = $DriveHashTable.$Drive.Item(2)
    $DriveBackupLocation = $DriveHashTable.$Drive.Item(3)

    Write-Output "[*] Checking group membership"

    $GroupMembers = @()
    ForEach ($Item in $GroupMembership) {

        $Data = $Item.PartComponent -split "\,"
        $Name = ($Data[1] -split "=")[1]
        $GroupMembers += ("$Name`n").Replace("""","")

    }  # End ForEach

            # Knicks is the group name                  # This knicks is the Key Variable name
    If (($GroupNames.Contains('Knicks') -and $Drive -eq 'Knicks') -or ($GroupNames.Contains('Bulls') -and $Drive -eq 'Bulls') -or ($GroupNames.Contains('Staff') -and $Drive -eq 'User Share Drive')) {

        If (!(Get-PsDrive -Name $DrivesLetter -ErrorAction 'SilentlyContinue') ) {

            Try {

		Write-Output "[*] Mapping drive $DriveLetter"
                New-PSDrive -Name $DrivesLetter -Root $DriveLocation -PSProvider 'FileSystem' -Persist -Scope 'Global' -ErrorAction 'SilentlyContinue'

            } # End try
            Catch {

                Write-Output "[!] Failed to map $DriveLetter. Attempting backup location"
                New-PSDrive -Name $DrivesLetter -Root $DriveBackupLocation -PSProvider 'FileSystem' -Persist -Scope 'Global' -ErrorAction 'SilentlyContinue'

            } # End Catch

        } # End If

    }  # End If

}  # End ForEach
