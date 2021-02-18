Write-Output "[*] Stopping services that use the directories we need renamed"
Stop-Service -Name wuauserv,cryptsvc,bits,msiserver

Write-Output "[*] Renaming C:\Windows\SoftwareDistribution to SoftwareDistribution.bak"
Rename-Item -Name "C:\Windows\SoftwareDistribution" -NewName "C:\Windows\SoftwareDistribution.bak"

Write-Output "[*] Renaming C:\Windows\System32\catroot2 to catroot2.bak"
Rename-Item -Name "C:\Windows\System32\catroot2" -NewName "C:\Windows\System32\catroot2.bak"

Write-Output "[*] A restart is required to load the changes. Update Windows After the restart"
Restart-Computer -Confirm
