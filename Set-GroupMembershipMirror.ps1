<#
.SYNOPSIS
This cmdlet is used to add members in an existing AD group to a new existing group in AD to mirror the user list. This will not remove anyone from a group. It in essence copies the members of one group over to another group.


.DESCRIPTION
This works by checking the existence of the groups defined in the parameters. If the groups both exist execution continues. The group members are then obtained from the control group before being added to the other existing group.


.PARAMETER Group
This parameter defines the AD group Name property of a group holding members you want mirrored to another group

.PARAMETER NewGroup
This parameter defines the AD group Name property of the group you want to add members too

.PARAMETER UseLDAPS
This switch parameter indicates you want to use LDAP over SSL on port 636 to add members instead of port 389


.EXAMPLE
Set-GroupMembershipMirror -Group GroupA -NewGroup AddMembersToMe
# This example adds all of the group members in 'GroupA' to the 'AddMembersToMe' group using LDAP

.EXAMPLE
Set-GroupMembershipMirror -Group "Group A" -NewGroup "Add Members To Me" -UseLDAPS
# This example adds all of the group members in 'Group A' to the 'Add Members To Me' group using LDAP over SSL


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


.OUTPUTS
None

#>
Function Set-GroupMembershipMirror {
    [CmdletBinding()]
        param(
            [Parameter(
                Mandatory=$True,
                Position=0,
                ValueFromPipeline=$False,
                HelpMessage="Define a group by its name that contains the members you want added to a new group.")]  # End Parameter
            [string]$Group,

             [Parameter(
                Mandatory=$True,
                Position=1,
                ValueFromPipeLine=$False,
                HelpMessage="Define the name of a group you want members added too.")]  # End Parameter
            [string]$NewGroup,

            [Parameter(
                Mandatory=$False)]  # End Parameter
            [Switch][Bool]$UseLDAPS

        )  # End param

BEGIN {

    $DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $PDC = $DomainObj.PdcRoleOwner.Name
    [Array]$GroupMembers = @()

    $GroupFound = Get-AdObject -Filter 'Name -like $Group' -Properties *
    $NewGroupFound = Get-AdObject -Filter 'Name -like $NewGroup' -Properties *

    If ( ($GroupFound) -and ($NewGroupFound) ) {

        Write-Verbose "[*] Both defined groups were successfully discovered in AD"

        $FindGroup = Get-ADGroup -Identity $GroupFound.DistinguishedName -Server $PDC -Properties *
        $NewGroupDN = $NewGroupFound.DistinguishedName

    }  # End If
    Else {

        Throw "The group name you specified was not found in AD"


    }  # End Else

    $Port = 389
    If ($UseLDAPS.IsPresent) {

        $Port = 636

    }  # End If

}  # End BEGIN
PROCESS
{

    Write-Verbose "[*] Getting member properties"
    ForEach ($Member in $FindGroup.member) {

        $GroupMembers += Get-ADObject -Filter 'DistinguishedName -like $Member'

    }  # End ForEach


    # Mirror the members to their new group
    ForEach ($Member in $GroupMembers) {

        $DN = $Member.DistinguishedName
        $FullName = $Member.Name

        $Management = [adsi]"LDAP://$PDC:$Port/$NewGroupDN"
        $User = "LDAP://$PDC:$Port/$DN"

        Write-Output "[*] Adding $FullName to $Group Group"
        $Management.Add($User)

    }  # End ForEach

}  # End PROCESS

}  # End Function Set-GroupMembershipMirror
