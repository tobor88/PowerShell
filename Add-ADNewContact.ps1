<#
.SYNOPSIS
Add-ADNewContact is a cmdlet that is used adding a new contact into Active Directory and adding them into a distribution group.
In order for this to work you will need to add the Contact OU location in Active Directory. This can be found on the Domain Controllers ADSI Edit MMC.
You will also need to define the location of the admin account you use to access Active Directory. This is done at line 77

.DESCRIPTION
Create a new Active Directory Contact and adds them to a distribution group(s).
In order for this to work you will need to add the Contact OU location in Active Directory. This can be found on the Domain Controllers ADSI Edit MMC.
You will also need to define the location of the admin account you use to access Active Directory. This is done at line 77

CONFIGURE LINE 77 ManagementUserAccount Variable


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
Add-ADNewContact -ContactName $ContactName -ContactEmail $ContactEmail -GroupName "Group1", "Group2"

.EXAMPLE
Add-ADNewContact -ContactName $ContactName -ContactEmail $ContactEmail -GroupName $GroupName -Verbose
#>

Function Add-ADNewContact {
    [CmdletBinding()]
        param(
        [Parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="New Contacts Name. `n Example: Dixie Normus `n`n If you see this message, you will need to enter the new contacts name.")] # End Parameter
            [ValidateNotNullorEmpty()]
        [string[]]$ContactName,

        [Parameter(Mandatory=$True,
                Position=1,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="New Contacts Email Address. `n Example: Dixie.Normus@osbornepro.com `nnIf you see this message, you will need to enter the new contacts email address.")] # End Parameter
            [ValidateNotNullorEmpty()]
        [string[]]$ContactEmail,

        [Parameter(Mandatory=$True,
                Position=2,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Add to Group's Name. `n Example: Distribution Group `n`nIf you see this message, you will need to enter the groups name to add the contact too.")] # End Parameter
            [ValidateNotNullorEmpty()]
        [string[]]$GroupName) # End param

    BEGIN {

        Import-Module ActiveDirectory

    } # End BEGIN

    PROCESS {

            $Username = $env:USERNAME
            $Path = "ou=CONTACTS,dc=OSBORNEPRO,dc=COM"

            Write-Verbose "New contact will be added to the below OU`n$Path`n"

            $NameCount = $ContactName.Split(' ').Count
            If ($NameCount -eq 2) {

                $FirstName,$LastName = $ContactName.Split(' ')

                New-ADObject -Type Contact -Name $ContactName -Path $Path -OtherAttributes @{'GivenName'="$FirstName";'SN'="$LastName";'Mail'=$ContactEmail;'ProxyAddresses'="SMTP:"+$ContactEmail;'targetAddress'="SMTP:"+$ContactEmail}

                ForEach ($GName in $GroupName) {

                    $ManagementUserAccount = [adsi] "LDAP://usav-dcp:389/cn=$Username,cn=Users,dc=OSBORNEPRO,dc=COM"
                    $NewContact = "LDAP://usav-dcp:389/cn=$Gname,$Path"
                    $ManagementUserAccount.Add($NewContact)

                } # End ForEach

            } # End If

            ElseIf ($NameCount -eq 3) {

                $FirstName,$MiddleName,$LastName = $ContactName.Split(' ')
                New-ADObject -Type Contact -Name $ContactName -Path $Path -OtherAttributes @{'GivenName'="$FirstName";'SN'="$LastName";'Mail'=$ContactEmail;'ProxyAddresses'="SMTP:"+$ContactEmail;'targetAddress'="SMTP:"+$ContactEmail}

                ForEach ($GName in $GroupName) {

                    $ManagementUserAccount = [adsi] "LDAP://usav-dcp:389/cn=$Username,cn=Users,dc=OSBORNEPRO,dc=COM"
                    $NewContact = "LDAP://usav-dcp:389/cn=$Gname,$Path"
                    $ManagementUserAccount.Add($NewContact)

                } # End ForEach

            } # End Elseif

            ElseIf ($NameCount -ge 4 ) {

                Throw "[x] Too many names for this cmdlet to handle."

            } # End ElseIf

} # End Function
