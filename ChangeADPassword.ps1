##############################################################################################
#                                                                                            #
# Last Modified" 1/27/2023                                                                   #
#                                                                                            #
# Description: This script allows you to change the password of a user in Active Directory   #
#              without needing to be logged into a domain joined computer.                   #
#                                                                                            #
# Requirement: Communication with the Domain Controller you specify                          #
#                                                                                            #
##############################################################################################

$DC = Read-Host -Prompt "[?] Enter the name or IP Address of the domain controller EXAMPLE: server.domain.com "
$Credential = Get-Credential -Message "Enter your credentials for the specified domain"
$DomainEntry = New-Object -TypeName System.DirectoryServices.DirectoryEntry "LDAP://$($DC)" ,$Credential.UserName,$($Credential.GetNetworkCredential().Password)
$Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
$Searcher.SearchRoot = $DomainEntry
$Searcher.Filter = "(samaccountname=$($Credential.UserName))"

$User = $Searcher.FindOne()
$UserObject = New-Object -TypeName System.DirectoryServices.DirectoryEntry $User.Path, $Credential.UserName, $($Credential.GetNetworkCredential().Password)
If ($UserObject) {

    Write-Output -InputObject "[*] Changing password for user: $($User.Path)"
    $UserObject.ChangePassword($Credential.GetNetworkCredential().Password, [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((Read-Host -Prompt "Enter your new password" -AsSecureString))))

} Else {

    Throw "$($Credential.UserName) not found"

}  # End If Else
