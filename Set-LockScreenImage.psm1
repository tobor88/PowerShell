<#
.SYNOPSIS
	Set-LockScreenImage function is used to set the lock screen image of a remote computer.
	The image is copied from the file server and than set as the lock screen image.

.DESCRIPTION
	Set-LockScreenImage sets the lock screen image for company computers.
	I recommend using the Verbose paramter to monitor progress

.NOTES
	Author: Rob Osborne
	Alias: tobor
	Contact: rosborne@osbornepro.com
	https://roberthosborne.com

.EXAMPLE
	Set-LockScreenImage -Path \\files\networkshare$

	The above commands changes the lock screen image for the local computer

.EXAMPLE
	Set-LockScreenImage -ComputerName Dirka1 -Path \\files\networkshare$ -Verbose

	The above command changes the lock screen image for a remote computer verbosely

#>

Function Set-LockScreenImage
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,
			 Position = 0,
			 HelpMessage = "Enter the name of a remote computer. Leave blank to change local host's lock screen.")]
		[string[]]$ComputerName,

			 [Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = "Enter the network directory location of the new lock screen image. Leave blank to use the default image.")]
		[string[]]$Path) # End param


	If ($null -ne $ComputerName)
	{

		$TestConnection = Test-Connection -ComputerName $ComputerName -Count 1

		If (!($TestConnection))
		{

			Write-Warning "Could not ping remote host"

			Read-Host "Press Ctrl+C to cancel script or press Enter to continue anyway."

		} # End If
		Else
		{
			$Cred = Get-Credential -Message "Enter admin credentials to make changes on the remote machine."

			Write-Verbose "Connection test to $ComputerName was successful..."

			$Session = New-PsSession -ComputerName $ComputerName -Credential $Cred -EnableNetworkAccess

			Invoke-Command -Session $Session -ScriptBlock { New-PsDrive -Name Q -PSProvider FileSystem -Root '\\networkshare\files$\Backgrounds' -Description "Temp mapping for lock screen image transfer." -Scope Global -Persist -Verbose -Credential (Get-Credential -Message "Credentials need to be entered again on the remote machine because it is a different machine.") }

		} # End Else

		Invoke-Command -Session $Session -ScriptBlock {

			Write-Verbose "Setting lock screen image for $ComputerName"

			Write-Verbose "Creating copy location..."

			$LocalImageLocation = 'C:\Users\Public\Pictures\LockScreenImage.png'

			$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"

			$PropertyName = "LockScreenImage"

			Write-Verbose "Copying image to local location..."

			Copy-Item -Path "Q:\LockScreenImage.png" -Destination $LocalImageLocation -Force | Out-Null

			If (!(Test-Path -Path $RegistryPath))
			{

				Write-Verbose "Registry path $RegistryPath does not exist. Creating entry..."

				New-Item -Path $RegistryPath -Name LockScreenImage -Force | Out-Null

			} # End If

			If (!((Get-ItemProperty -Path $RegistryPath).$PropertyName))
			{

				Write-Verbose "Creating Item Property"

				New-ItemProperty -Path $RegistryPath -Name $PropertyName -Value $LocalImageLocation | Out-Null

			} # End If

			Write-Verbose "Setting Item Property..."

			Set-ItemProperty -Path $RegistryPath -Name $PropertyName -Value $LocalImageLocation | Out-Null

			Get-ItemProperty -Path $RegistryPath -Name $PropertyName

			Write-Verbose "Updating lock screen image change..."

			$Command = @'
C:\Windows\System32\cmd.exe /C C:\Windows\System32\rundll32.exe user32.dll, UpdatePerUserSystemParameters
'@
			Try
			{

				Invoke-Expression -Command:$Command

			} #  End Try
			Catch
			{

				Start-Process -FilePath "C:\Windows\System32\cmd.exe" -ArgumentList '/c  user32.dll, UpdatePerUserSystemParameters'

			} # End Catch

		} # End ScriptBlock

		Invoke-Command -Session $Session -ScriptBlock { Remove-PsDrive -Name Q -PSProvider FileSystem -Scope Global }

		Remove-PSSession $Session

	} # End If
	Else
	{

		$ComputerName = $env:COMPUTERNAME

		Write-Verbose "Setting lock screen image for $ComputerName"

		Write-Verbose "Creating copy location..."

		New-PSDrive -Name Q -Root '\\networkshare\files$\Backgrounds' -PSProvider FileSystem -Scope Global -Persist -Description "Temp mapping for lock screen image file." | Out-Null

		$LocalImageLocation = 'C:\Users\Public\Pictures\LockScreenImage.png'

		$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"

		$PropertyName = "LockScreenImage"

		Write-Verbose "Copying image to local location..."

		Copy-Item -Path "Q:\LockScreenImage.png" -Destination $LocalImageLocation -Force | Out-Null

		If (!(Test-Path -Path $RegistryPath))
		{

			Write-Verbose "Registry path $RegistryPath does not exist. Creating entry..."

			New-Item -Path $RegistryPath -Name LockScreenImage -Force | Out-Null

		} # End If

		If (!((Get-ItemProperty -Path $RegistryPath).$PropertyName))
		{

			Write-Verbose "Creating Item Property"

			New-ItemProperty -Path $RegistryPath -Name $PropertyName -Value $LocalImageLocation | Out-Null

		} # End If

		Write-Verbose "Setting Item Property..."

		Set-ItemProperty -Path $RegistryPath -Name $PropertyName -Value $LocalImageLocation | Out-Null

		Get-ItemProperty -Path $RegistryPath -Name $PropertyName

		Write-Verbose "Updating lock screen image change..."

		$Command = @'
C:\Windows\System32\cmd.exe /C C:\Windows\System32\rundll32.exe user32.dll, UpdatePerUserSystemParameters
'@
		Try
		{

			Invoke-Expression -Command:$Command

		} #  End Try
		Catch
		{

			Start-Process -FilePath "C:\Windows\System32\cmd.exe" -ArgumentList '/c  user32.dll, UpdatePerUserSystemParameters'

		} # End Catch

		Remove-PSDrive -Name Q -PSProvider FileSystem -Scope Global -Force

	} # End Else

} # End Funciton
