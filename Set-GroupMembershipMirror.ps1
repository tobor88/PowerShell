<#
.NAME 
    Set-GroupMembershipMirror


.SYOPSIS
    This function is used to take all the members of a distribution group and add them to a different group. 
    No members are removed from the group. They are only mirrored to a new group.


.NOTES
    Author: Robert H. Osborne
    Alias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthosborne.om


.SYNTAX
    Set-GroupMembershipMirror [-Group] <string> [-NewGroup] <string> [<CommonParameters>]


.DESCRIPTION
    The Set-GroupMembershipMirror cmdlet gets the members of an Active Directory group and adds all it's members
    to another group.


.PARAMTERS
    -Group <AD Group Name>
        The -Group parameter will define a group name whose members will be added to the -NewGroup value

        Specifies an Active Directory group object by providing one of the following values. The identifier in parentheses is the LDAP display name for the attribute.

        Name (Name)
        
        Example: Employees
        
        Display Name (DisplayName)
        
        Example: Contacts

        Required?                    true
        Position?                    0
        Default value                
        Accept pipeline input?       true
        Accept wildcard characters?  false


    -NewGroup <AD Group Name>
        The -NewGroup parameter defines the group name which members of the -Group value will be added too

        Specifies an Active Directory group object by providing one of the following values. The identifier in parentheses is the LDAP display name for the attribute.

        Name (Name)
        
        Example: Employees
        
        Display Name (DisplayName)
        
        Example: Contacts
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false


    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 

.INPUTS
    Name of DisplayName attribute of an Active Directory group object


.OUTPUTS
    Microsoft.ActiveDirectory.Management.ADObject Derived types, such as the following are also accepted:   Microsoft.ActiveDirectory.Management.ADGroup   Microsoft.ActiveDirectory.Management.ADUser   
    Microsoft.ActiveDirectory.Management.ADComputer   Microsoft.ActiveDirectory.Management.ADServiceAccount   Microsoft.ActiveDirectory.Management.ADOrganizationalUnit   
    Microsoft.ActiveDirectory.Management.ADFineGrainedPasswordPolicy   Microsoft.ActiveDirectory.Management.ADDomain
    
    Returns one or more Active Directory objects.
        
    The Get-ADObject cmdlet returns a default set of ADObject property values. To retrieve additional ADObject properties, use the Properties parameter of the cmdlet.
        
    To view the properties for an ADObject object, see the following examples. To run these examples, replace <object> with an Active Directory object identifier.
        
    To get a list of the default set of properties of an ADObject object, use the following command:
        
    Get-ADObject <object>| Get-Member
        
    To get a list of all the properties of an ADObject object, use the following command:
        
    Get-ADObject <object> -Properties ALL | Get-Member

#>
Function Set-GroupMembershipMirror {
    [CmdletBinding()]
        param(
            [Parameter(
                Mandatory=$True, 
                Position=0,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Define a group by its name that contains the members you want added to a new group.")]
            [string]$Group,

             [Parameter(
                Mandatory=$True, 
                Position=1,
                ValueFromPipeline=$False,
                ValueFromPipelinByPropertyName=$False,
                HelpMessage="Define the name of a group you want members added too.")]
            [string]$NewGroup)  # End param

BEGIN 
{

    $DomainInfo = Get-ADDomain

    If ($DomainInfo)
    {
        
        $PDC = $DomainInfo.InfrastructureMaster

    }  # End If
    Else
    {

        throw "[!] This function will only work if run on a domain controller"

    }  # End Else

    [array]$GroupMembers = @()

    $GroupFound = Get-AdObject -Filter 'Name -like $Group' -Properties *

    $NewGroupFound = Get-AdObject -Filter 'Name -like $NewGroup' -Properties *

    If ( ($GroupFound) -and ($NewGroupFound) )
    {
        
        Write-Verbose "[*] Both defined groups were successfully discovered in AD"

        $FindGroup = Get-ADGroup -Identity $GroupFound.DistinguishedName -Server $PDC -Properties *

        $NewGroupDN = $NewGroupFound.DistinguishedName

    }  # End If
    Else
    {

        throw "A group name you specified was not found in AD"
        
        
    }  # End Else

}  # End BEGIN
PROCESS
{
    
    Write-Verbose "[*] Getting member properties"

    ForEach ($Member in $FindGroup.member)
    {

        $GroupMembers += Get-ADObject -Filter 'DistinguishedName -like $Member'

    }  # End ForEach

    # Mirror the members to their new group
    ForEach ($Member in $GroupMembers)
    {

        $DN = $Member.DistinguishedName
        $FullName = $Member.Name

        $Management = [adsi]"LDAP://$PDC`:389/$NewGroupDN" 
        $User = "LDAP://$PDC`:389/$DN"

        Write-Verbose "[*] Adding $FullName to $Group." 

        $Management.Add($User) 

    }  # End ForEach

}  # End PROCESS
END
{

    Write-Verbose "[*] Below is the member list of the changed group."

    Get-AdObject -Filter 'Name -like $NewGroup' -Properties * 

}  # End END

}  # End Function Set-GroupMembershipMirror
