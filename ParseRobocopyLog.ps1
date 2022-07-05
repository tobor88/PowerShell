$Path = Read-Host -Prompt "Enter the directory path location contianing your robocopy logs `nNOTE: This filters for all TXT files in the directory you specify`n`nEXAMPLE: C:\Temp\Logs"
$Files = Get-ChildItem -Path $Path -Filter "*.txt" -File

$Results = @()
$ErrorFileResults = @()

ForEach ($File in $Files.FullName) {

    Write-Output "[*] Parsing $File"
    $Started = ((Select-String -Path $File -Pattern " Started : " -Context 14,7 | Out-String).Trim()).Split(">")
    For ($i = 0; $i -le $Started.Count; $i++) {

        $Instance = ((Select-String -Path $File -Pattern " Started : " -Context 14,7 | Out-String).Trim()).Split(">")[$i]
        If (($Instance | Out-String) -like "*Total *Copied * Skipped * Mismatch * FAILED * Extras*") { 

            [array]$Start = (Select-String -Path $File -Pattern " Started : " | Out-String).Trim().Split([Environment]::NewLine)
            For ($n = 0; $n -le $Start.Count; $n++) {

                Try { $Begin = ((Select-String -Path $File -Pattern " Started : " | Out-String).Trim().Split([Environment]::NewLine)[$n]).Split(" ") } Catch { Break }
                Try { $S = Get-Date -Date "$($Begin[-6]) $($Begin[-5]) $($Begin[-4]) $($Begin[-3]) $($Begin[-2]) $($Begin[-1])" -Format 'MM/dd/yyyy hh:mm:ss' } Catch { $S = "NA" }
                Try { $Source = ((Select-String -Path $File -Pattern "Source : " | Out-String).Trim().Split([Environment]::NewLine)[$n]).Split(":")[-1].Trim() } Catch { $Source = "NA" }
                Try { $Dest = ((Select-String -Path $File -Pattern "Dest : " | Out-String).Trim().Split([Environment]::NewLine)[$n]).Split(":")[-1].Trim() } Catch { $Dest = "NA" }
                Try { $FileCounts = (Select-String -Path $File -Pattern "Files : " | Out-String).Trim().Split([Environment]::NewLine)[$n] } Catch { $FileCounts = "NA" }
                Try { 
                
                    $Try = 3
                    $Total = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()
                    If ($Total.Length -eq 0) {

                        $Try++
                        $Total = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                        If ($Total.Length -eq 0) {

                            $Try++
                            $Total = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                            If ($Total.Length -eq 0) {

                                $Try++
                                $Total = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                            }  # End If

                        }  # End If

                    }  # End If

                    
                } Catch { 
                
                    $Total = "NA" 
                    
                }  # End If

                If ($Total -ne "NA") {

                    Try { 
                    
                        $Try++
                        $Copied = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()
                        
                        If ($Copied.Length -eq 0) {

                            $Try++
                            $Copied = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                            If ($Copied.Length -eq 0) {

                                $Try++
                                $Copied = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                If ($Copied.Length -eq 0) {

                                    $Try++
                                    $Copied = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                }  # End If

                            }  # End If

                        }  # End If
                        
                    } Catch { 
                    
                        $Copied = 0
                        
                    }  # End Try Catch

                    Try { 
                    
                        $Try++
                        $Skipped = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()
                        If ($Skipped.Length -eq 0) {

                            $Try++
                            $Skipped = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                            If ($Skipped.Length -eq 0) {

                                $Try++
                                $Skipped = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                If ($Skipped.Length -eq 0) {

                                    $Try++
                                    $Skipped = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                }  # End If

                            }  # End If

                        }  # End If
                        
                    } Catch { 
                    
                        $Skipped = 0
                        
                    }  # End Try Catch
                    
                    Try { 
                    
                        $Try++
                        $Mismatch = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()
                        If ($Mismatch.Length -eq 0) {

                            $Try++
                            $Mismatch = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                            If ($Mismatch.Length -eq 0) {

                                $Try++
                                $Mismatch = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                If ($Mismatch.Length -eq 0) {

                                    $Try++
                                    $Mismatch = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                }  # End If

                            }  # End If

                        }  # End If
                        
                    } Catch { 
                    
                        $Mismatch = 0
                        
                    }  # End Try Catch

                    Try { 
                    
                        $Try++
                        $Failed = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()
                        If ($Failed.Length -eq 0) {

                            $Try++
                            $Failed = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                            If ($Failed.Length -eq 0) {

                                $Try++
                                $Failed = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                If ($Failed.Length -eq 0) {

                                    $Try++
                                    $Failed = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                }  # End If

                            }  # End If

                        }  # End If
                        
                    } Catch { 
                    
                        $Failed = 0
                        
                    }  # End Try Catch
                    
                    Try { 
                    
                        $Try++
                        $Extras = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim() 
                        If ($Extras.Length -eq 0) {

                            $Try++
                            $Extras = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                            If ($Extras.Length -eq 0) {

                                $Try++
                                $Extras = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                If ($Extras.Length -eq 0) {

                                    $Try++
                                    $Extras = ($FileCounts.Replace("  ","|").Split("|")[$Try]).Trim()

                                }  # End If

                            }  # End If

                        }  # End If
                        
                    } Catch { 
                    
                        $Extras = 0
                        
                    }
                    $DestinationCount = [Int]$Copied + [Int]$Skipped
                    $ByteInfo = (Select-String -Path $File -Pattern "Bytes : " | Out-String).Trim().Split([Environment]::NewLine)[$Evens]
                    Try { $TotalBytes = $ByteInfo.Replace("  ","|").Split("|")[2].Trim() } Catch { $TotalBytes = 0}
                    Try { $CopiedBytes = $ByteInfo.Replace("  ","|").Split("|")[3].Trim() } Catch { $CopiedBytes = 0}
                    Try { $SkippedBytes = $ByteInfo.Replace("  ","|").Split("|")[4].Trim() } Catch { $SkippedBytes = 0}
                    #If ($CopiedBytes.length -gt 1) { $Cb = ($CopiedBytes.Replace("m","").Replace("k","").Replace("b","").Replace("t","").Replace("g","").Trim()) } Else { $Cb = 0 }
                    #If ($SkippedBytes.length -gt 1) { $Ob = ($SkippedBytes.Replace("m","").Replace("k","").Replace("b","").Replace("g","").Replace("t","").Trim()) } Else { $Ob = 0 }
                    #$DestBytes = [Int]$Cb + [Int]$Ob

                    $Results += New-Object -TypeName PSCustomObject -Property @{
        
                        Started=$($S);
                        Source=$($Source);
                        TotalSourceFiles=$Total;
                        Destination=$($Dest);
                        TotalDestFiles=$($DestinationCount);
                        TotalBytes=$($TotalBytes);
                        #TotalDestBytes=$($DestBytes);
                        CopiedBytes=$($CopiedBytes);
                        SkippedBytes=$($SkippedBytes);
                        LogFile=$($File);

                    }  # End New-Object -Property
          
                }  # End If

            }  # End For

        }  # End If
    
    }  # End For

    $Errors = (Select-String -Pattern "ERROR (\d){0,3}" -Path $File | Out-String).Trim().Split([Environment]::NewLine) # \((0x8(.*){5,20})\)" -Path $File
    ForEach ($Err in $Errors) {

        If ($Err -match '(0x(.*){5,20})') {

            $ErrorCode = $Err.Split("(").Split(")")[1]
            $FilePath = $Err.Split(")")[-1].Substring(13).Trim()
            Switch ($ErrorCode) {

                "0x00000000" { $ErrorMessage = "The operation completed successfully" }
                "0x00000002" { $ErrorMessage = "File not found error" }
                "0x00000003" { $ErrorMessage = "File not found errors" }
                "0x00000005" { $ErrorMessage = "Access denied errors" }
                "0x00000006" { $ErrorMessage = "Invalid handle errors" }
                "0x00000020" { $ErrorMessage = "The process cannot access the file because it is being used by another process" }
                "0x00000035" { $ErrorMessage = "Network path not found errors" }
                "0x00000040" { $ErrorMessage = "The specified network name is no longer available" }
                "0x00000070" { $ErrorMessage = "Disk full errors" }
                "0x00000079" { $ErrorMessage = "Semaphore timeout errors" }
                "0x00000033" { $ErrorMessage = "Network path errors" }
                "0x0000003B" { $ErrorMessage = "An unexpected network error occurred" }
                "0x0000003A" { $ErrorMessage = "NTFS security errors" }
                "0x0000054F" { $ErrorMessage = "Internal errors" }

            }  # End Switch

            $ErrorFileResults += New-Object -TypeName PSCustomObject -Property @{
                ErrorCode=$ErrorCode;
                ErrorMessage=$ErrorMessage;
                FilePath=$FilePath;
            }  # End New-Object -Property

        }  # End If

    }  # End ForEach

}  # End ForEach

$Results | Out-GridView -Title "Parent Directory Summary"
$ErrorFileResults | Out-GridView -Title "Individual File Errors"

