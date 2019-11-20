<#
.SYNOPSIS
    Perform LDAP Queries of the current domain. This requires a user account in order to execute the cmdlet.
    
    There seems to be an issue querying LDAP while device is connceted over Direct Access


.NOTES
    Author: Rob Osborne
    ALias: tobor
    Contact: rosborne@osbornepro.com
    https://roberthsoborne.com



.SYNTAX
    Get-LdapInfo [ -DomainAdmins | -DomainControllers | -UAC ]



.PARAMETER

    -DomainAdmins       [<SwitchParameter>]

        The switch parameter is used to tell the cmdlet to obtain a list of members of the Domain Admins Group


    -DomainControllers  [<SwitchParameter>]

         This switch is used to tell the cmdlet to get a list of the Domain's Controllers


    -UAC                [<SwitchParameter>]

        This switch parameter is used to tell the cmdlet to get a list of UAC Permissions that can be delegated



.INPUTS
    SwitchParameters



.OUTPUTS

    IsPublic IsSerial Name                                     BaseType
    -------- -------- ----                                     --------
    True     True     Object[]                                 System.Array



.EXAMPLE

    -------------------------- EXAMPLE 1 --------------------------

    C:\PS> Get-LdapInfo -DomainAdmins

    # This example gets a list of users in the Domain Admins group



    C:\PS> Get-LdapInfo -DomainControllers

    # This example displays a list of the domains Domain Controllers. Whene executed as an Administrator you will receive the local admin password



    C:\PS> Get-LdapInfo -UAC

    # This example gets a list of users with Undelegated Admin abilities for User Access Control

#>
Function Get-LdapInfo {
    [CmdletBinding()]
        param(
            [Parameter(
                Mandatory=$False)]
            [switch][bool]$DomainControllers,

            [Parameter(
                Mandatory=$False)]
            [switch][bool]$DomainAdmins,

            [Parameter(
                Mandatory=$False)]
            [switch][bool]$UAC

        ) # End param

BEGIN
{

    If ($DomainControllers.IsPresent)
    {

        $LdapFilter = "(primaryGroupID=516)"

    } # End If
    ElseIf ($DomainAdmins.IsPresent)
    {

        $LdapFilter =  "(&(objectCategory=person)(objectClass=user)((memberOf=CN=Domain Admins,OU=Admin Accounts,DC=Domain,DC=Com)))"
    
    } # End ElseIf
    ElseIf ($UAC.IsPresent)
    {

        $LdapFilter =  "(userAccountControl:1.2.840.113556.1.4.803:=524288)"
        
    } # End ElseIf
    
} # End BEGIN

PROCESS
{

    $Domain = New-Object System.DirectoryServices.DirectoryEntry
    $Search = New-Object System.DirectoryServices.DirectorySearcher
    
    $Search.SearchRoot = $Domain
    $Search.Filter = $LdapFilter
    $Search.SearchScope = "Subtree"

    $Results = $Search.FindAll()

    ForEach ($Result in $Results)
    {

        $Object = $Result.GetDirectoryEntry()

        $Object

    } # End ForEach

} # End PROCESS

END
{

    Write-Verbose "LDAP Query complete. "

} # End END

} # End Get-LdapInfo
