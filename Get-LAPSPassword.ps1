Function Get-LAPSPassword {
    [CmdletBinding()]
        param(
            [Parameter(
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$False
                HelpMessage="Define the domain controller to query for the LAPS password `nEXAMPLE: dc01.osbornepro.com"
            )]  # End Parameter
            [String]$Server,
            
            [Parameter(
                Position=1,
                Mandatory=$True,
                ValueFromPipeline=$False
                HelpMessage="Define the machine name to obtain the LAPS password of `nEXAMPLE: desktop01.osbornepro.com"
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

    If (Test-NetTcpConnection -ComputerName $PrimaryDC -Port 389 -Quiet -ErrorAction Continue) {
      
        Write-Error "[x] Could not reach LDAP port 389 on $PrimaryDC. Trying to obtain password anyway"
    
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
