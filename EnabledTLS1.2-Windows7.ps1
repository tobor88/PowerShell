$Reg = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\'
$Name1 = 'DefaultSecureProtocols '
$Value1 = 'AA0'

$Registry = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727','HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319','HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727','HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319'
$Name2 = 'SystemDefaultTlsVersions'
$Value2 = '1'
$Name3 = 'SchUseStrongCrypto'

New-ItemProperty -Path $Reg -Name $Name1 -Value $Value1 -Force
New-ItemProperty -Path $Registry -Name $Name2 -Value $Value2
New-ItemProperty -Path $Registry -Name $Name3 -Value $Value2
