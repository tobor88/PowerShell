<#
.SYNOPSIS
This cmdlet can be used to retrieve the LAPS password using an LDAP query from a domain joined device. This will always return the LAPS username as Administrator


.DESCRIPTION
Retrieve the LAPS password of a computer on a remote domain joined device. The username will always be returned as Administrator


.PARAMETER Server
Define the Active Directory server to perform your query against for the LAPS password

.PARAMETER ComputerName
Define the name of the computer you want to retrieve the LAPS password for

.EXAMPLE
Get-LAPSPassword -Server DC01.osbornepro.com -ComputerName Desktop02
# The example performs an LDAP query against DC01.osbornepro.com for the Desktop02 LAPS password

.EXAMPLE
Get-LAPSPassword -Server DC01.osbornepro.com -ComputerName Desktop02 -Group "OSBORNEPRO\LAPS-Admin"
# The example performs an LDAP query against DC01.osbornepro.com for the Desktop02 LAPS password and verifies you have permissions to grab the password


.INPUTS
None


.OUTPUTS
None


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://github.com/tobor88
https://github.com/osbornepro
https://www.powershellgallery.com/profiles/tobor
https://osbornepro.com
https://writeups.osbornepro.com
https://btpssecpack.osbornepro.com
https://www.powershellgallery.com/profiles/tobor
https://www.hackthebox.eu/profile/52286
https://www.linkedin.com/in/roberthosborne/
https://www.credly.com/users/roberthosborne/badges
#>
Function Get-LAPSPassword {
    [CmdletBinding()]
        param(
            [Parameter(
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Define the domain controller to query for the LAPS password `nEXAMPLE: dc01.osbornepro.com"
            )]  # End Parameter
            [String]$Server,
            
            [Parameter(
                Position=1,
                Mandatory=$True,
                ValueFromPipeline=$False,
                HelpMessage="Define the machine hostname to obtain the LAPS password of. (Not FQDN) `nEXAMPLE: desktop01"
            )]  # End Parameter
            [String]$ComputerName,
            
            [Parameter(
                Position=2,
                Mandatory=$False,
                ValueFromPipeline=$False
                #HelpMessage="Enter the security group required to read the LAPS passwords in Active Directory `nEXAMPLE: OSBORNEPRO.COM\LAPS-Admins"
            )]  # End Parameter
            [String[]]$Group
        )  # End param

    $Domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
    $DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    
    If ($Null -eq $Server) {
    
        $Server = ($DomainObj.PdcRoleOwner).Name
        
    }  # End If

    If (Test-NetTcpConnection -ComputerName $Server -Port 389 -ErrorAction Continue) {
      
        Write-Error "[x] Could not reach LDAP port 389 on $Server. Trying to obtain password anyway"
    
    }  # End If

    # Verifying LAPS group membership
    If ($Group) {
        
        $CurrentUserId = [Security.Principal.WindowsIdentity]::GetCurrent()
        $GroupMembership = $CurrentUserId.Groups | ForEach-Object {

            $_.Translate([Security.Principal.NTAccount])

        }  # End ForEach-Object
            
        ForEach ($G in $Group) {

            If (!($GroupMembership.Value.Contains("$($G)"))) {

                Throw "[x] $($CurrentUserId.Name) does not have permissions to access LAPS"

            }  # End If

        }  # End ForEach
            
    }  # End If

    # Use LDAP to search Active Directory for LAPS
    $SearchString =  "LDAP://" + $Server + ":389/"
    $LdapFilter = "(Name=$ComputerName)"
    $ObjDomain = New-Object -TypeName System.DirectoryServices.DirectoryEntry
    $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher([ADSI]$SearchString)
       
    $DistinguishedName = "CN=$ComputerName,*,DC=$($DomainObj.Name.Replace('.',',DC='))"
    $SearchString += $DistinguishedName

    $Searcher.SearchRoot = $ObjDomain
    $Searcher.Filter = $LdapFilter
    $Searcher.SearchScope = "Subtree"
    $Searcher.FindAll() | ForEach-Object {

        $LAPS = $Null
        $CompObject = $_.GetDirectoryEntry()
        If ($Null -ne $($CompObject.'ms-Mcs-AdmPwd')) {
           
            $LAPS = $($CompObject.'ms-Mcs-AdmPwd'.Replace("{","").Replace("}",""))
               
        }  # End If

        $Results = New-Object -TypeName PSCustomObject -Property @{
            HostName=$($CompObject.Name.Replace("{","").Replace("}",""));
            Username="Administrator";
            Password=$LAPS;
            Domain=$Domain
         }  # End New-Object Property

    }  # End ForEach-Object
       
    If ($Null -ne $Results) {

        Return $Results

    } Else {

        Write-Error "[x] No LAPS password found for $ComputerName on $Server"

    }  # End If Else

}  # End Function Get-LocalAdminPassword
