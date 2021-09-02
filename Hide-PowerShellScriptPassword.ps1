<#
.SYNOPSIS
Hide-PowerShellScriptPassword is a cmdlet that is used to create a couple of keys that can be used to prevent storing a password
in clear text inside of a PowerShell script. It creates and AES encrypted file contents and key to unlock the secret and never
display the password in clear text. This should be run as an administrator.

.DESCRIPTION
Create multiple files that can be used to prevent the usage of clear text passwords stored in clear text.
This should be run as an administrator.
Get-RandomHexNumber was taken from https://powershell.org/forums/topic/generating-a-20-character-hex-string-with-powershell/


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
Hide-PowerShellScriptPassword
#>

Function Hide-PowerShellScriptPassword {
    [CmdletBinding()]
        param() # End param

    BEGIN {

       $KeyFilePath = "C:\Users\Public\Documents\Keys"
       $AESPasswordPath = "C:\Users\Public\Documents\Password"

        Function Get-RandomHexNumber{
            param(
                [int] $length = 20,
                [string] $chars = "0123456789ABCDEF") # End param

        $Bytes = New-object "System.Byte[]" $Length
        $Rnd = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $Rnd.GetBytes($Bytes)
        $Result = ""
        1..$Length | Foreach {

            $Result += $Chars[ $Bytes[$_] % $Chars.Length ]

        } # End Foreach

        $Result

        } # End Function Get-RandomHexNumber

    } # End BEGIN

    PROCESS {

        Write-Verbose "Creating a random 32-bit key and storing it to a file. (Maximum Key Size is 32)"

        $Var = Get-RandomHexNumber -Length 20
        $KeyFile = New-Item -ItemType File -Name $Var -Path $KeyFilePath -Force
        $Key = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
        $Key | Out-File $KeyFile

        Write-Verbose "Encryption key file has been created."

    } # End PROCESS

    END {

        Write-Verbose "Invoking the stored key to create the encrypted password"

        $Pass = Read-Host -Prompt "Enter the password you want to AES encrypt for a script"
        $PasswordFile = New-Item -ItemType File -Name "$Var.txt" -Path $AESPasswordPath -Force
        $KeyFile = "$KeyFilePath\$Var"
        $Key = Get-Content -Path $KeyFile
        $Password = "$Pass" | ConvertTo-SecureString -AsPlainText -Force
        $Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile


        Write-Host "Use the below lines to insert your encrypted credentials into the script"
        Write-Host " "
        Write-Host '$User = "account@osbornepro.com"'
        Write-Host '$PasswordFile = "$AESPasswordPath\$Var.txt"'
        Write-Host '$KeyFile = "$KeyFilePath\$Var"'
        Write-Host '$key = Get-Content $KeyFile'
        Write-Host '$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)'
        Write-Host " "
        Write-Host 'Below is an example of how to insert the password value into a Get-Credential type of cmdlet'
        Write-Host " "
        Write-Host 'Invoke-Command -Credential $cred'
        Write-Host " "
        Write-Host "Add the below variable to insert the password into a string. Someone skilled can reverse this method. `nUse above method if available."
        Write-Host '$SecurePass = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password)'
        Read-Host '$PassString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($SecurePass)'

    } # End END

} # End Function Hide-PowerShellScriptPassword
