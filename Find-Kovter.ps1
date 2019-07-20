<#
.Synopsis
    Find-Kovter is a cmdlet created to find Kovter Malware in the Windows Registry. 
    This cmdlet was designed for system administrators. No switches need to be defined other than the computer to run this on if desired.

.DESCRIPTION
    This cmdlet searches the Windows Registry for Kovter Malware
    If more than one file are found, more than one location will be returned.
    Written by Rob Osborne - rosborne@osbornepro.com
    Alias: tobor

.EXAMPLE
   Find-Kovter -ComputerName $ComputerName

.DESCRIPTION
    The ComputerName switch used with Find-Kovter is used for checking a remote computer for Kovter malware.

.EXAMPLE
   Find-Kovter -Verbose

.DESCRIPTION
    The verbose parameter can be used to see where the script is at as it runs.
#>

Function Find-Kovter {
    [CmdletBinding()]
        param( 
            [Parameter(Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="Enter The hostname of the remote computer you want to check.")] # End Parameter
            [string[]]$ComputerName
        ) # End param
BEGIN {

    $KovterNames = 'Win32:Kovter-C', 'Win32/Kovter.C', 'Trojan:Win32/Kovter!rfn', 'Trojan.GenericKD.3112101 (B)', 'Trojan.Kotver', 'Trojan.Kotver!gen1', 'Trojan.Ransomlock.AK', 'Trojan.Ransomlk.AK!gm', 'Symantec', 'Trojan.Win32.Kovter.evv', 'Trojan.GenericKD.3112101', 'Ransom_.956D2004', 'Trojan.GenericKD.3112101', 'Trojan.Kovter!Tocgra7MIok', 'TR/Kovter.352313', 'Trojan.Kovter.88', 'Trojan/Kovter.c', 'Trojan.Win32.Z.Kovter', 'Trojan.Kovter'
    
    Write-Verbose 'Begining search for Kovter. `nStep 1.) Checking processes...'

    $Infection = Get-Process -ComputerName $ComputerName -Name mshta

} # End BEGIN

PROCESS {

    if ($Infection) {
        
        Write-Verbose 'Matching Process found for Kovter infection. Begining Registry Search for known Kovter Names.'

        start https://www.bleepingcomputer.com/virus-removal/remove-kovter-trojan
        
        sleep 3
        
        start https://www.bleepingcomputer.com/download/rkill/

    } # End If

    else { Write-Verbose "Kovter has not been found by it's common name in Processes. `n`nBegin checking registry..." }
    
    foreach($kovter in $KovterNames) {
            
            Write-Verbose "Checking Windows Registry for Kovter Malware. `nPlease Wait..."
 
            Get-ChildItem -Path HKCU:\Software -Filter $kovter -Recurse -ErrorAction SilentlyContinue
    
        } # End ForEach

} # End Function
