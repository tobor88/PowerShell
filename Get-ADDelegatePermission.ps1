Function Get-ADDelegatePermission {
<#
.SYNOPSIS
This cmdlet is used to retrieve Delegate Permissions fora  group(s) in Active Directory


.DESCRIPTION
Return all groups or specify a group(s) to return delegate permissions on an Active Directory container(s)


.PARAMETER Group
Define a group or groups you want to view the delegate permissions for on an Active Directory container(s)

.PARAMETER OU
Define an OU or CN in Active Directory you wish to view the delegate permissions for

.PARAMETER IsInherited
When defined this will return directly applied permissions and inherited permissions for an Active Directory container 


.EXAMPLE
Get-ADDelegatePermissions
# This examples returns all delegate permissions on all Active Directory organizationl units (OU's)

.EXAMPLE
Get-ADDelegatePermissions -Group "DOMAIN\Domain Admins"
# This examples returns all Domain Adminis group delegate permissions for all Active Directory organizationl units (OU's)

.EXAMPLE
Get-ADDelegatePermissions -Group "DOMAIN\Domain Admins" -OU "CN=Users,DC=osbornepro,DC=com"
# This examples returns all Domain Adminis group delegate permissions for the CN=Users container in Active Directory


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.INPUTS
System.String[]


.OUTPUTS
PSCustomObject


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
            [String[]]$Group,
            
            [Parameter(
                Position=1,
                Mandatory=$False,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$False
            )]  # End Parameter
            [Alias("OUPath","OrganizationlUnit")]
            [String[]]$OU = (Get-ADOrganizationalUnit -Filter *).DistinguishedName,
            
            [Parameter(
                Mandatory=$False
            )]  # End Parameter
            [Switch][Bool]$IsInherited
        )  # End param

BEGIN {

    $DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $PrimaryDC = ($DomainObj.PdcRoleOwner).Name

    If ($PrimaryDC -notlike "$env:COMPUTERNAME*") {

        Throw "[x] You can only execute this script on $PrimaryDC"

    }  # End If
    
    $Inherited = $False
    If ($IsInherited.IsPresent) {
    
        $Inherited = $True
    
    }  # End If

    If ($PSBoundParameters.ContainsKey("Group")) {

        $Groups = @()
        $NetBiosDomain = (Get-CimInstance -ClassName Win32_NTDomain -Verbose:$False).DomainName
        $Group | ForEach-Object { 
        
            If ($_ -notlike "*\*") {

                $Groups += "$($NetBiosDomain)\$($_)"
                Write-Verbose -Message "Adding $NetBiosDomain as the domain for $_ : $($NetBiosDomain)\$($_)"
        
            } Else {
            
                $Groups += $_
                Write-Verbose -Message "Using $_ in groups filter"

            }  # End If Else
        
        }  # End ForEach-Object
        
    }  # End If

    Import-Module -Name ActiveDirectory -Verbose:$False
    $Results = @()
    $OriginalDirectory = $PWD
    Set-Location -Path "AD:\"

} PROCESS {

    ForEach ($O In $OU) {

        $ADO = Get-ADOrganizationalUnit -Filter "DistinguishedName -like '$O'"
        If ($Null -eq $ADO) {

            Write-Verbose -Message "Returngin AD Object because OU does not exist"
            $ADO = Get-ADObject -Filter "DistinguishedName -like '$O'"

            If ($Null -eq $ADO) {

                Write-Error -Message "[x] No results container could be found in Active Directory for $OU"
                Return

            }  # End If

        }  # End If

        $ACLs = (Get-Acl -Path "AD:\$($ADO.DistinguishedName)").Access
        ForEach ($ACL in $ACLs) {

            If ($Inherited -eq $False) {

                If ($ACL.IsInherited -eq $False) {

                    $Results += New-Object -TypeName PSCustomObject -Property @{
                        Identity = $ACL.IdentityReference;
                        ADRights = $ACL.ActiveDirectoryRights;
                        AccessControlType = $ACL.AccessControlType;
                        IsInherited = $ACL.IsInherited;
                        OU = $ADO.DistinguishedName;
                    }  # End New-Object -Property

                }  # End If

            } ElseIf ($Inherited -eq $True) {
            
                $Results += New-Object -TypeName PSCustomObject -Property @{
                    Identity = $ACL.IdentityReference;
                    ADRights = $ACL.ActiveDirectoryRights;
                    AccessControlType = $ACL.AccessControlType;
                    IsInherited = $ACL.IsInherited;
                    OU = $ADO.DistinguishedName;
                }  # End New-Object -Property
            
            } Else {
            
                Write-Error -Message "[x] There was an issue with the `$Inherited variable and $($ADO.DistinguishedName)"
            
            }  # End If ElseIf Else

        }  # End ForEach

    }  # End ForEach

} END {

    Set-Location -Path $OriginalDirectory
    If ($PSBoundParameters.ContainsKey("Group")) {

        Write-Verbose -Message "Filtering the results for the below groups `n$Groups"
        $Results = $Results | Where-Object -Property Identity -in $Groups

    }  # End If

    If ($Results) {

        Return $Results

    } Else {
    
        Write-Output -InputObject "[i] No results returned using your query"
    
    }  # End If ElseIf

}  # End BPE

}  # End Function Get-ADDelegatePermission
