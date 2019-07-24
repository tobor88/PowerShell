#--------------
# REQUIREMENTS #
#--------------
#===================================================================================================
#
# For this script to work you will need KiTTY installed. This can be changed by you of course.
# SSH port 22 will need to be open on the switch
# A TFTP server will need to be listening and accessible over the network on port 69
#
#====================================================================================================
#
# This backup scripts has been tested with the following Cisco Switch Models
# -  SG250-26P 26-Port Gigabit PoE Smart Switch 
# -  SG250-50P 
# -  Cisco SG300-52 
# -  Cisco Catalyst 9200 
#
#=====================================================================================================

$TftpServerIP = "192.168.1.69"
$SwitchIP = "192.168.1.5"
$SshPassword = "P@ssw0rd!"
$SshUsername = "cisco"
$LogFilePath = C:\Users\Public\Documents\Logs
$PathToKiTTY = C:\Users\Public\Desktop\KiTTY.exe

# I formatted the date with the year first for better organization in the folder.
$FormatedDate = Get-Date -Format 'yyyyMMdd-HHmm'

$Date = Get-Date -Format M.d.yyyy

$ConfigFile = $SwitchIP + "_" + $FormatedDate + ".txt" 
$LogFile = $SwitchIP + "_" + $FormatedDate + ".log" 
$SshCommand = @"
$username
$SshPassword
copy running-config tftp://$TftpServerIP/SwitchIP_$Date.txt
logout
exit
logout
"@
    $KiTTYCommands = {echo y | $PathToKiTTY $SwitchIP -ssh -v -l $SshUsername -pw $pass -cmd $sshCommand -log "$LogFilePath\$SwitchIP_$FormatedDate.txt"}

    & $KiTTYCommands

    sleep -s 1
 
