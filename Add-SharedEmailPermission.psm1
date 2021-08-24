<#
.SYNOPSIS
Add-SharedEmailPermission is a cmdlet created to add a user to a shared mailbox in Office365

.DESCRIPTION
Add-SharedEmailPermission is a cmdlet used to add a user(s) to a shared email in Office365.
This cmdlet will allow piping of a username but does not accept more than one username.

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
Add-SharedEmailPermission -Identity <string[] UserPrincipalName> -Mailbox <string[] Shared Email Address> [-SendAs] [-FullAccess] [-Verbose]

.EXAMPLE
Add-SharedEmailPermission -Identity 'rob.osborne@osbornepro.com' -Mailbox 'derpadoo@osbornepro.com' -FullAccess -Verbose
This example adds rob.osborne@osbornepro.com to have full access rights on shared mailbox derpadoo@osbornepro.com

.EXAMPLE
Add-SharedEmailPermission -Identity 'rob.osborne@osbornepro.com' -Mailbox 'derpadoo@osbornepro.com' -SendAs -FullAccess -Verbose
This example adds rob.osborne@osbornepro.com to have full access and SendAs rights on shared mailbox derpadoo@osbornepro.com

.EXAMPLE
Add-SharedEmailPermission -Identity 'rob.osborne@osbornepro.com' -Mailbox 'derpadoo@osbornepro.com' -FullAccess
This example adds rob.osborne@osbornepro.com to have full access rights on shared mailbox derpadoo@osbornepro.com
#>
Function Add-SharedEmailPermission {
    [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter the user(s) you want to add to a shared mailbox. Separate email addresses with a comma. Example: rob@osbornepro.com, osborne@osbornepro.com")]
            [string]$Identity,

            [Parameter(Mandatory=$True,
                Position=1,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter the shared mailbox email address. Example: dirka@osbornepro.com")]
            [string]$Mailbox,

            [Parameter(Mandatory=$False)]
            [switch][bool]$SendAs,

            [Parameter(Mandatory=$False)]
            [switch][bool]$FullAccess) # End param

    If (!($SendAs.IsPresent -or $FullAccess.IsPresent)) {

        Throw 'Missing Switch Permission'

    } # End If

    If ((Get-PsSession).ConfigurationName -notlike 'Microsoft.Exchange') {

        $Session = New-PSSession -ConfigurationName "Microsoft.Exchange" -ConnectionUri "https://ps.outlook.com/PowerShell-LiveID?PSVersion=5.1.14393.2608" -Credential (Get-Credential -Message "Enter your global admin credentials for Office365. Example: admin@osbornepro.com") -Authentication "Basic" -AllowRedirection
        Import-PSSession -Session $Session -ErrorAction "SilentlyContinue" | Out-Null

    } # End If

    If ($SendAs.IsPresent) {

        Write-Verbose "Adding SendAs Permission to user $Identity for shared mailbox $Mailbox"
        Add-RecipientPermission -Identity $Identity -Trustee $Mailbox -AccessRights 'SendAs'

    } #End If

    If ($FullAccess.IsPresent) {

        Write-Verbose "Adding full permissions for $Identity to shared mailbox $Mailbox"
        Add-MailboxPermission -Identity $Identity -User $Mailbox -AccessRights 'FullAccess' -InheritanceType 'All'

    } # End If

    If ((Get-PsSession).ConfigurationName -like 'Microsoft.Exchange') {

        Get-PsSession | Where-Object -Property 'ConfigurationName' -like 'Microsoft.Exchange' | Remove-PsSession

    } # End If

} # End Function Add-SharedEmailPermission
