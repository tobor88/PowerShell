<#
.SYNOPSIS
    Clear-AllPsHistory is used to clear the contents of a computers PowerShell command history file and the shell's current command history.DESCRIPTION

.SNYTAX
    Clear-AllPsHistory [-Verbose]

.DESCRIPTION
    Clears the contents of PowerShell's history file and the shell history.

.INPUTS
    Does not accept any pipeline input.

.OUTPUTS
    No Output. This clears PowerShell command history.

.EXAMPLE
    -------------------------- EXAMPLE 1 --------------------------
    C:\PS> Clear-AllPsHistory -Verbose
    This command clears all PowerShell command history and shows the steps verbosely.

#>
Function Clear-AllPsHistory
{

    $History = Get-PSReadlineOption

    $HistoryFile = $History.HistorySavePath

    Write-Verbose 'Clearing Console history...'

    Clear-History

    Write-Verbose "Emptying contents of $HistoryFile"

    Clear-Content -Path $HistoryFile -Force

} # End Function
