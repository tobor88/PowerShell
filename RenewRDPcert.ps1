$CurrentCertificate = Get-CimInstance -Class "Win32_TSGeneralSetting" -Namespace "Root/CimV2/TerminalServices" -Filter "TerminalName='RDP-tcp'"
certreq -enroll -machine -q -PolicyServer * -cert ($CurrentCertificate.SSLCertificateSHA1Hash) renew reusekeys
