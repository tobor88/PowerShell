$NameFilter = Read-Host -Prompt "Enter your Root CA's name `nEXAMPLE something-CA"
Try {

    $Certificate = Get-ChildItem -Path "Cert:\CurrentUser\AuthRoot" -Recurse -ExpiringInDays 30 | Where-Object -Property Subject -like "*$($NameFilter)*" | Sort-Object -Descending -Property "NotBefore" | Select-Object -First 1

} Catch {

    Write-Output "[i] PowerShell version is not current. Using older method to filter for expiring Root Certificate"
    $Certificate = Get-ChildItem -Recurse | Where-Object -FilterScript { ($_.NotAfter -le (Get-Date).AddDays(30)) -and ($_.Subject -like "*$($NameFilter)*") } | Sort-Object -Descending -Property "NotBefore" | Select-Object -First 1

}  # End Try Catch

If ($Certificate) {

    $ExpiresOn = Get-Date -Date $Certificate.NotAfter -Format "MM/dd/yyyy hh:mm:ss"
    Write-Output "[!] Root Certificate Authority Certificate is expiring in 30 days or less `n`tEXPIRES ON: $($ExpiresOn)"
    # Create a Teams webhook in the helpdesk so a ticket gets created when this happens

} Else {
   
    Write-Output "[*] Root CA Certificate is valid. `n`tEXPIRES ON: $(Get-Date -Date $Certificate.NotAfter -Format "MM/dd/yyyy hh:mm:ss")"
    
} # End If Else
