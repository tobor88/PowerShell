# This script can be used to retrieve the LAPS password of a computer
If (!([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]'Administrator')) {
    
    If ([Int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {

        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit

    }  # End If

}  # End If

$Output = @()
$Credential = Get-Credential -Message "Enter your AD credentials"
$Domain = Read-Host -Prompt "Enter the domain to authenticate too `nEXAMPLE: osbornepro.com"
$ComputerName = Read-Host -Prompt "Enter the hostname want to retrieve the LAPS password for `nEXAMPLE: DC01"
$DomainContext = New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList ('Domain', "$Domain", $Credential.UserName , $Credential.GetNetworkCredential().Password)
$DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
$PrimaryDC = ($DomainObj.PdcRoleOwner).Name
$ObjDomain = New-Object -TypeName System.DirectoryServices.DirectoryEntry("LDAP://$PrimaryDC", $Credential.UserName, $Credential.GetNetworkCredential().Password)

$SearchString =  "LDAP://" + $PrimaryDC + ":389/DC=$($DomainObj.Name.Replace('.',',DC='))"
$Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher([ADSI]$SearchString)
$Searcher.SearchRoot = $ObjDomain
$Searcher.Filter = "(&(objectCategory=computer)(name=$ComputerName))"
$Searcher.SearchScope = "Subtree"

$Results = $Searcher.FindAll()
ForEach ($Result in $Results) {

    $Output += $Result.GetDirectoryEntry()

}  # End ForEach
$Output | Select-Object -Property 'cn','ms-Mcs-AdmPwd'
