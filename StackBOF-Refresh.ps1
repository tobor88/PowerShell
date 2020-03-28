# IMPORTANT NOTE: I made this to spped up the process of testing a BOF in the PWK course. All this script does is restart a service if it is not running and opens Immunity Debuger.

# Run script as administrator
param([switch]$Elevated)

Function Test-Admin 
{

  $CurrentUser = New-Object -TypeName Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

}  # End Test-Admin

If ((Test-Admin) -eq $False)  
{

    If (!($Elevated))
    {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-nologo -noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    
    }  # End Else

Exit

}

# Quickly Start SyncBreeze and Open Immunity Debugger as Admin

$Status = (Get-Service -Name "Sync Breeze Enterprise").Status
$IDAProcess = (Get-Process -Name "ImmunityDebugger" -ErrorAction SilentlyContinue).ProcessName

If ($Status -notlike 'Running')
{

	Start-Service -Name "Sync Breeze Enterprise"

}  # End If
Else
{

	Write-Host "SyncBreeze Service is already running. Since you ran this script I am going to restart it." -ForegroundColor Green

	Restart-Service -Name "Sync Breeze Enterprise" -Confirm

}  # End Else

$CurrentStatus = (Get-Service -Name "Sync Breeze Enterprise").Status

Start-Sleep -Seconds 1

Write-Host "SyncBreeze Status: $CurrentStatus" -ForegroundColor Cyan


If ($IDAProcess)
{

	Stop-Process -Name ImmunityDebugger -Force
	Set-Location -Path C:\Users\Public\Desktop
	& '.\Immunity Debugger.lnk'

}  # End If
Else
{

	Set-Location -Path C:\Users\Public\Desktop
	 & '.\Immunity Debugger.lnk'

}  # End Else
