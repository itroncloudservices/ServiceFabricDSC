Configuration ServiceFabric
{  
	  
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
        
    Node ServiceFabricNode
	{
        Script SetServers
        { 
            #Credential = $cred
            GetScript=
            {
                $res = w32tm /query /peers
                $groups = ([regex]::Match($res,'Peer: (\S*)')).Groups
                if ($groups.Count -eq 2)
                {
                    write-warning "GetScript " $groups[1].Value
                    return @{Result = $groups[1].Value};
                }
                else
                {
                    write-warning "GetScript - blank"
                    return @{Result = ""};
                }
            }
            SetScript = 
            { 
                write-warning "INFO : Setting NTP info"
                REG ADD HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v Enabled /t REG_DWORD /d 0 /f 
                REM Set the service
                W32TM /config /manualpeerlist:"time.windows.com,0x9" /syncfromflags:MANUAL /update
                
                REG ADD HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Config /v MinPollInterval /t REG_DWORD /d 8 /f 
                REG ADD HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Config /v MaxPollInterval /t REG_DWORD /d 10 /f 
                
                REM Windows Time Restart Service
                NET STOP W32TIME
                NET START W32TIME
                w32tm /resync 
            }
            TestScript=
            {
                $reg = Get-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider -Name Enabled
                $NTPServers = "time.windows.com,0x9"
                $res = w32tm /query /peers
                $groups = ([regex]::Match($res,'Peer: (\S*)')).Groups
                if ($groups.Count -eq 2 -And $groups[1].Value -eq $NTPServers -and $reg.Enabled -eq 0 )
                {
                    return $true;
                }
                else
                {
                    return $false;
                }
            }
        }  
    }
} 
