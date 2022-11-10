Function New-ADDelegatePermissionGuid {
<#
.SYNOPSIS
This cmdlet is used to generate a unique GUID value for Special permissions or Extended Rights permissions in Active Directory


.DESCRIPTION
Create a GUID mapping for either Special Permissions or Extended Rights permissions in Active Directory that will be assigned to an object


.PARAMETER RootDSE
Return the RootDSE object for a domain. Grabs the local domain by default

.PARAMETER ExtendedRights
Returns GUID mappings for Extended Rights permissions in Active Directory instead of Special Permissions


.EXAMPLE
New-ADDelegatePermissionGuid
# Generates GUID values for all possible permissions in Active Directory on the local domain

.EXAMPLE
New-ADDelegatePermissionGuid -RootDSE (Get-ADRootDSE -Credential (Get-Credential))
# Generates GUID values for all possible permissions in Active Directory on the local domain


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.INPUTS
None


.OUTPUTS
None


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
    [CmdletBinding()]
        param(
            [Parameter(
                Position=0,
                Mandatory=$False,
                ValueFromPipeline=$False
            )]  # End Parameter
            [Object]$RootDSE = $(Get-ADRootDSE),

            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [Switch][Bool]$ExtendedRights
        )  # End param

    $DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $PrimaryDC = ($DomainObj.PdcRoleOwner).Name
    If ($PrimaryDC -notlike "$env:COMPUTERNAME*") {

        Throw "[x] You can only execute this script on $PrimaryDC"

    }  # End If

    $GuidMap = @{}
    If ($ExtendedRights.IsPresent) {

        Write-Verbose -Message "Mapping Extended Rights permissions to GUIDs"
        $PermissionType = "Extended"
        Get-ADObject -SearchBase $RootDSE.ConfigurationNamingContext -LDAPFilter "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties @("displayName", "rightsGuid") | ForEach-Object { 
    
            $GuidMap[$_.DisplayName] = [System.GUID]$_.RightsGuid
        
        }  # End ForEach-Object

    } Else {

        Write-Verbose -Message "Mapping Special Permissions to GUIDs"
        $PermissionType = "Special"
        Get-ADObject -SearchBase $RootDSE.SchemaNamingContext -LDAPFilter "(schemaidguid=*)" -Properties @("LdapDisplayName", "SchemaIdGUID") | ForEach-Object { 
    
            $GuidMap[$_.LdapDisplayName] = [System.GUID]$_.SchemaIdGUID
        
        }  # End ForEach-Object

    }  # End If Else

    $Names = ($GuidMap.Keys | Out-String).Split("$([System.Environment]::NewLine)")
    $Names = $Names  | Where-Object -FilterScript { $_ -ne ""}
    $Guids = $GuidMap.Values.Guid
    For ($i = 0; $i -lt $Names.Count; $i++) {
     
        New-Object -TypeName PSCustomObject -Property @{
            Permission=$Names[$i];
            Guid=$Guids[$i];
            Type=$PermissionType;
        }  # End New-Object -Property
    
    }  # End For

}  # End Function New-ADDelegatePermissionGuid
