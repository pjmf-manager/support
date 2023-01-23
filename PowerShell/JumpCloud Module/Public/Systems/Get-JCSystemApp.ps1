function Get-JCSystemApp () {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $false, HelpMessage = 'The System Id of the system you want to search for applications')]
        [string]$SystemID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, HelpMessage = 'The type (windows, mac, linux) of the JumpCloud Command you wish to search ex. (Windows, Mac, Linux))')]
        [ValidateSet('Windows', 'MacOs', 'Linux')]
        [string]$SystemOS,
        [Parameter(Mandatory = $false, HelpMessage = 'The name of the application you want to search for ex. (JumpCloud-Agent, Slack)')]
        [string]$SoftwareName,
        [Parameter(Mandatory = $false, HelpMessage = 'The version of the application you want to search for ex. (1.1.2)')]
        [string]$SoftwareVersion,
        [Parameter(Mandatory = $false, HelpMessage = 'Search for a specific application by name from all systems in the org')]
        [switch]$Search
    )
    begin {
        Write-Verbose 'Verifying JCAPI Key'
        if ($JCAPIKEY.length -ne 40) {
            Connect-JCOnline
        }
        $Parallel = $JCConfig.parallel.Calculated
        $searchAppResultsList = New-Object -TypeName System.Collections.ArrayList
        if ($Parallel) {
            Write-Verbose 'Initilizing resultsArray'
            $resultsArrayList = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
        } else {
            Write-Verbose 'Initilizing resultsArray'
            $resultsArrayList = New-Object -TypeName System.Collections.ArrayList
        }
    }
    process {
        [int]$limit = '1000'
        Write-Verbose "Setting limit to $limit"

        [int]$skip = '0'
        Write-Verbose "Setting skip to $skip"
        $applicationArray = @('programs', 'apps', 'linux_packages')
        # Search
        if ($Search) {
            # Get all the results
            $applicationArray | ForEach-Object {
                $URL = "$JCUrlBasePath/api/v2/systeminsights/$($_)"
                Write-Verbose "Searching for $SoftwareName in $_"
                if ($Parallel) {
                    $searchAppResults = Get-JCResults -URL $URL -Method "GET" -limit $limit -parallel $true
                } else {
                    $searchAppResults = Get-JCResults -URL $URL -Method "GET" -limit $limit
                }
                # Add OS Family to results
                if ($_ -eq 'programs') { $os = 'Windows' }
                elseif ($_ -eq 'apps') { $os = 'MacOs' }
                elseif ($_ -eq 'linux_packages') { $os = 'Linux' }
                $searchAppResults | Add-Member -MemberType NoteProperty -Name 'osFamily' -Value $os
                [void]$searchAppResultsList.Add($searchAppResults)
            }

            # softwarename search
            if ($SoftwareName) {
                $searchAppResultsList | ForEach-Object {
                    $results = $_ | Where-Object { $_.name -match $SoftwareName }
                    $results | ForEach-Object {
                        $resultsArrayList.Add($_)
                    }
                }

            }

        } elseif ($SystemId -or $SystemOs) {
            if ($SystemId) {
                $OSType = Get-JCSystem -ID $SystemID | Select-Object -ExpandProperty osFamily
            } elseif ($SystemOs) {
                $OSType = $SystemOs
            }
            if ($OsType -eq 'MacOs') { $Ostype = 'Darwin' } # OS Family for Mac is Darwin

            Write-Debug "OS: $OSType"
            switch ($OSType) {
                'Windows' {
                    # If Software title and system ID are passed then return specific app
                    if ($SoftwareVersion -and $SoftwareName ) {
                        # Handle Special Characters
                        $SoftwareName = [System.Web.HttpUtility]::UrlEncode($SoftwareName)
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/programs?filter=name:eq:$SoftwareName&filter=version:eq:$SoftwareVersion"

                    } elseif ($SoftwareName -and $SystemID) {
                        # Handle Special Characters
                        $SoftwareName = [System.Web.HttpUtility]::UrlEncode($SoftwareName)
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/programs?filter=system_id:eq:$SystemID&filter=name:eq:$SoftwareName"
                    } elseif ($SoftwareName) {
                        # Add filter for system ID to $Search
                        $SoftwareName = [System.Web.HttpUtility]::UrlEncode($SoftwareName)
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/programs?filter=name:eq:$SoftwareName"
                    } elseif ($SystemID) {
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/programs?filter=system_id:eq:$SystemID"
                    } else {
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/programs"
                    }
                    Write-Debug $URL
                }
                'Darwin' {
                    # If Software title and system ID are passed then return specific app
                    if ($SoftwareVersion -and $SoftwareName) {
                        # Handle Special Characters
                        $SoftwareName = [System.Web.HttpUtility]::UrlEncode($SoftwareName)
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/apps?filter=bundle_name:eq:$SoftwareName&filter=bundle_version:eq:$SoftwareVersion"

                    } elseif ($SoftwareName -and $SystemID) {
                        # Handle Special Characters
                        $SoftwareName = [System.Web.HttpUtility]::UrlEncode($SoftwareName)
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/apps?filter=system_id:eq:$SystemID&filter=bundle_name:eq:$SoftwareName"
                    } elseif ($SoftwareName) {
                        # Add filter for system ID to $Search
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/apps?filter=bundle_name:eq:$SoftwareName"
                    } elseif ($SystemID) {
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/apps?filter=system_id:eq:$SystemID"
                    } else {
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/apps"
                    }
                    Write-Debug $URL
                }
                'Linux' {
                    # If Software title and system ID are passed then return specific app
                    if ($SoftwareVersion -and $SoftwareName) {
                        # Handle Special Characters
                        $SoftwareName = [System.Web.HttpUtility]::UrlEncode($SoftwareName)
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/linux_packages?filter=name:eq:$SoftwareName&filter=version:eq:$SoftwareVersion"

                    } elseif ($SoftwareName -and $SystemID) {
                        # Handle Special Characters
                        $SoftwareName = [System.Web.HttpUtility]::UrlEncode($SoftwareName)
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/linux_packages?filter=system_id:eq:$SystemID&filter=name:eq:$SoftwareName"
                    } elseif ($SoftwareName) {
                        # Add filter for system ID to $Search
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/linux_packages?filter=name:eq:$SoftwareName"
                    } elseif ($SystemID) {
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/linux_packages?filter=system_id:eq:$SystemID"
                    } else {
                        $URL = "$JCUrlBasePath/api/v2/systeminsights/linux_packages"
                    }
                    Write-Debug $URL
                }

            }
            if ($Parallel) {
                $resultsArrayList = Get-JCResults -URL $URL -Method "GET" -limit $limit -parallel $true
            } else {
                $resultsArrayList = Get-JCResults -URL $URL -Method "GET" -limit $limit
            }

        } elseif ($SoftwareName) {
            $SoftwareName = [System.Web.HttpUtility]::UrlEncode($SoftwareName)
            # Foreach Mac, Windows, Linux
            foreach ($os in @('MacOs', 'Windows', 'Linux')) {
                if ($os -eq 'MacOs') {
                    $URL = "$JCUrlBasePath/api/v2/systeminsights/apps?filter=bundle_name:eq:$SoftwareName"
                    if ($Parallel) {
                        $resultsArray = Get-JCResults -URL $URL -Method "GET" -limit $limit -parallel $true
                    } else {
                        $resultsArray = Get-JCResults -URL $URL -Method "GET" -limit $limit
                    }
                    $resultsArray | Add-Member -MemberType NoteProperty -Name 'osFamily' -Value $os
                    $resultsArrayList.Add($resultsArray)
                } elseif ($os -eq 'Windows') {
                    $URL = "$JCUrlBasePath/api/v2/systeminsights/programs?filter=name:eq:$SoftwareName"
                    if ($Parallel) {
                        $resultsArray = Get-JCResults -URL $URL -Method "GET" -limit $limit -parallel $true
                    } else {
                        $resultsArray = Get-JCResults -URL $URL -Method "GET" -limit $limit
                    }
                    $resultsArray | Add-Member -MemberType NoteProperty -Name 'osFamily' -Value $os
                    $resultsArrayList.Add($resultsArray)
                } elseif ($os -eq 'Linux') {
                    $URL = "$JCUrlBasePath/api/v2/systeminsights/linux_packages?filter=name:eq:$SoftwareName"
                    if ($Parallel) {
                        $resultsArray = Get-JCResults -URL $URL -Method "GET" -limit $limit -parallel $true
                    } else {
                        $resultsArray = Get-JCResults -URL $URL -Method "GET" -limit $limit
                    }
                    $resultsArray | Add-Member -MemberType NoteProperty -Name 'osFamily' -Value $os
                    $resultsArrayList.Add($resultsArray)
                }
            }
        }
    }
    end {
        return $resultsArrayList
    }
} # End Function

