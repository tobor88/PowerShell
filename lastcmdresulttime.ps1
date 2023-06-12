Function Get-LastCmdResultTime {

    $LastCommandInfo = Get-History | Select-Object -Last 1
    $Result = $LastCommandInfo.EndExecutionTime - $LastCommandInfo.StartExecutionTime
    Return $Result

}  # End Function Get-LastCmdResultTime
