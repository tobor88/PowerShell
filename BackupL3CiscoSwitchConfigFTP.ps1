#--------------
# REQUIREMENTS #
#--------------
#===================================================================================================
#
# For this script to work you will need KiTTY installed. This can be changed by you of course.
# https://www.fosshub.com/KiTTY.html Download kitty at that link
#
# SSH port 22 will need to be open on the switch
# A FTP server will need to be listening and accessible over the network
#
# To use unexposed passwords use https://github.com/tobor88/PowerShell/blob/master/Hide-PowerShellScriptPassword.ps1 
# I have included how to incorporate the unexposed passwords in this script.
#
#====================================================================================================
#
# This backup scripts has been tested with the following Cisco Switch Models
# -  ASA Firewall 5010
# -  ASA Firewall 5016
# -  ASA Firewall 5505
#
# For this to work on the below switch model you will not need to confirm by renetering information.
#  For the SSH Command variable only include "enable" and copy run ftp://...
# -  Cisco Catalyst 9200 
#
#=====================================================================================================

$FtpServerIP = "192.168.1.21"
$SwitchIP = "192.168.1.5"
$LogFilePath = C:\Users\Public\Documents\Logs
$PathToKiTTY = C:\Users\Public\Desktop\KiTTY.exe

# Below credential is for logging into the switch over SSH.
$PasswordFile = "C:\Users\Public\Documents\Password\AESpassword.txt"
$KeyFile = "C:\Users\Public\Documents\keys\PasswordKey"
$key = Get-Content $KeyFile
$User = "cisco"
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
$SecurePass = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Cred.Password)
$Pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($SecurePass)
 
 # The below credentials are for logging into the FTP server.
$PasswordFile1 = "C:\Users\Public\Documents\Password\AESpassword1.txt"
$KeyFile1 = "C:\Users\Public\Documents\keys\PasswordKey1"
$key1 = Get-Content $KeyFile1
$User1 = "BatchJobAdmin"
$Cred1 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User1, (Get-Content $PasswordFile1 | ConvertTo-SecureString -Key $key1)
$SecurePass1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Cred1.Password)
$Pass1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($SecurePass1)

# I formatted the date with the year first for better organization in the folder.
$FormatedDate = Get-Date -Format 'yyyyMMdd-HHmm'
$Date = Get-Date -Format M.d.yyyy

$ConfigFile = $SwitchIP + "_" + $FormatedDate + ".txt" 
$LogFile = $SwitchIP + "_" + $FormatedDate + ".log"

$SshCommand = @"
en
$Pass
copy run ftp://$User1:$pass1@$FtpServerIP/$SwitchIP_$Date.txt
running-config
$SwitchIP
$User1
$pass1
$SwitchIP_$Date.txt
exit
logout
"@
    $KiTTYCommands = {echo y | $PathToKiTTY $SwitchIP -ssh -v -l $User -pw $Pass -cmd $sshCommand -log "$LogFilePath\$SwitchIP_$FormatedDate.txt"}

    & $KiTTYCommands

    sleep -s 1
    
    Remove-Variable User,Pass,User1,Pass1
 
