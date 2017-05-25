Configuration ServiceFabric
{  
	  
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    
    $NTPServers = "1.pool.ntp.org,2.pool.ntp.org"
    
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
                $NTPServers = "time.windows.com,0x9"
        	    write-warning "INFO : Configure NTP Service with param : $NTPServers"
			    w32tm /configure /manualpeerlist:$NTPServers /syncfromflags:manual /update
                if ((Get-Service -name W32Time).status -eq "Running" -eq $true)
                {
                    write-warning  "INFO : Stop NTP Service"	
			        net stop w32time 
                }
	            write-warning "INFO : Start NTP Service"
			    net start w32time

            }
            TestScript=
            {
                $NTPServers = "time.windows.com,0x9"
                $res = w32tm /query /peers
                $groups = ([regex]::Match($res,'Peer: (\S*)')).Groups
                if ($groups.Count -eq 2 -And $groups[1].Value -eq $NTPServers)
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
