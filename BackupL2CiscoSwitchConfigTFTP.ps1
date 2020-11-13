#--------------
# REQUIREMENTS #
#--------------
#===================================================================================================
#
# For this script to work you will need KiTTY installed. This can be changed by you of course.
# https://www.fosshub.com/KiTTY.html Download kitty at that link
#
# SSH port 22 will need to be open on the switch. If you use a different port modify the $KiTTYCommand variable to include your port
# A TFTP server will need to be listening and accessible over the network on port 69. This was testsed with SoloarWinds TFTP Server
# This can easily be converted to FTP. Some FTP servers require authentication in which case you will need to incorporate that into the commands
#
#====================================================================================================
#
# This backup scripts has been tested with the following Cisco Switch Models
# -  SG250-26P 26-Port Gigabit PoE Smart Switch 
# -  SG250-50P 
# -  Cisco SG300-52 
#
#=====================================================================================================

$TftpServerIP = "192.168.1.69" # I Used SolarWinds Free TFTP Server
$LogFilePath = C:\Users\Public\Documents\Logs # This will Log Credentials so I suggest if you use this that you modify the log files permissions
$PathToKiTTY = C:\Users\Public\Desktop\KiTTY.exe

# I formatted the date with the year first for better organization in the folder. These values are used in the file names that get saved
$FormatedDate = Get-Date -Format 'yyyyMMdd-HHmm'
$Date = Get-Date -Format M.d.yyyy



# Use This for multiple switches that use the same password. This is gong to execute if defined
$SwitchesToBackUP = 'switch1','10.10.10.10','switch.domain.com','switch4.domain.com'
$SshPassword = "P@ssw0rd!"
$SshUsername = "cisco"
# This ForEach loop is for Switches using the same username and password
ForEach ($SwitchIP in $SwitchesToBackUP)
{

    $ConfigFile = $SwitchIP + "_" + $FormatedDate + ".txt" 
    $LogFile = $SwitchIP + "_" + $FormatedDate + ".log" 

$SshCommand = @"
$username
$SshPassword
copy running-config tftp://$TftpServerIP/$SwitchIP_$Date.txt
logout
exit
logout
"@
    $KiTTYCommands = {echo y | $PathToKiTTY $SwitchIP -ssh -v -l $SshUsername -pw $pass -cmd $sshCommand -log "$LogFilePath\$SwitchIP_$FormatedDate.txt"}

    & $KiTTYCommands

    sleep -s 2

}  # End ForEach

# Use the hash table to define multiple switches that have different passwords. This is going to execute if defined
$SwitchHashTable = @{}

$SwitchHashTable.switch1 = @()
$SwitchHashTable.switch1 += "switch1"
$SwitchHashTable.switch1 += "cisco"
$SwitchHashTable.switch1 += "P@ssw0rd1!"

$SwitchHashTable.switch2 = @()
$SwitchHashTable.switch2 += "10.10.10.10"
$SwitchHashTable.switch2 += "admin"
$SwitchHashTable.switch2 += "Password123!"

$SwitchHashTable.switch3 = @()
$SwitchHashTable.switch3 += "switch.domain.com"
$SwitchHashTable.switch3 += "it"
$SwitchHashTable.switch3 += "pASSWORD1!"

$SwitchHashTable.switch4 = @()
$SwitchHashTable.switch4 += "switch4.domain.com"
$SwitchHashTable.switch4 += "root"
$SwitchHashTable.switch4 += "Passw0rd!"

# This ForEach Loop is for the switches with different usernames or passwords
ForEach ($Switch in $SwitchHashTable.Keys)
{

    $SSHUser = $SwitchHashTable.$Switch[1]
    $SSHPass = $SwitchHashTable.$Switch[2]

    $ConfigFile = $Switch + "_" + $FormatedDate + ".txt" 
    $LogFile = $Switch + "_" + $FormatedDate + ".log" 

$SshCommand = @"
$SSHUser
$SSHPass
copy running-config tftp://$TftpServerIP/$Switch_$Date.txt
logout
exit
logout
"@
    $KiTTYCommands = {echo y | $PathToKiTTY $Switch -ssh -v -l $SSHUser -pw $SSHPass -cmd $SshCommand -log "$LogFilePath\$Switch_$FormatedDate.txt"}

    & $KiTTYCommands

    sleep -s 2

}  # End ForEach
