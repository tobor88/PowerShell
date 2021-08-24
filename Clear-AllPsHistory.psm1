<#
.SYNOPSIS
    Clear-AllPsHistory is used to clear the contents of a computers PowerShell command history file and the shell's current command history.DESCRIPTION


.DESCRIPTION
Clears the contents of PowerShell's history file and the shell history.


.INPUTS
Does not accept any pipeline input.


.OUTPUTS
No Output. This clears PowerShell command history.

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
-------------------------- EXAMPLE 1 --------------------------
C:\PS> Clear-AllPsHistory -Verbose
This command clears all PowerShell command history and shows the steps verbosely.

#>
Function Clear-AllPsHistory {

    $History = Get-PSReadlineOption
    $HistoryFile = $History.HistorySavePath

    Write-Verbose 'Clearing Console history...'
    Clear-History

    Write-Verbose "Emptying contents of $HistoryFile"
    Clear-Content -Path $HistoryFile -Force

} # End Function
