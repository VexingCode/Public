Function Get-DeviceStatusReport {
    [CmdletBinding(DefaultParameterSetName = 'FromCsv')]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'FromCsv')]
        [string]$CsvPath,
        [Parameter(Mandatory, ParameterSetName = 'FromCsv')]
        [string]$CsvColumnName,
        [Parameter(Mandatory, ParameterSetName = 'FromText')]
        [string]$TextFilePath,
        [Parameter(Mandatory, ParameterSetName = 'Single')]
        [string]$ComputerName,
        [string]$SiteServer = "",
        [string]$SiteCode   = "",
        [string]$OutputFolder = "C:\Temp\SecOpsDvcCheck",
        [string]$FileNamePrefix = "DeviceCheckResults"
    )

    Function Get-TransitiveGroupMembersRecursive {
        Param (
            [string]$GroupId,
            [ref]$VisitedGroups,
            [ref]$ResolvedMembers
        )

        If ($VisitedGroups.Value -contains $GroupId) {
            return
        }

        $VisitedGroups.Value += $GroupId

        Try {
            $members = Get-MgBetaGroupMember -GroupId $GroupId -All
            ForEach ($member in $members) {
                $type = $member.AdditionalProperties.'@odata.type'
                Switch ($type) {
                    '#microsoft.graph.device' {
                        $ResolvedMembers.Value += $member
                    }
                    '#microsoft.graph.group' {
                        $nestedGroupId = $member.Id
                        Get-TransitiveGroupMembersRecursive -GroupId $nestedGroupId -VisitedGroups $VisitedGroups -ResolvedMembers $ResolvedMembers
                    }
                    Default {
                        [Console]::WriteLine("Unknown member type: $type")
                    }
                }
            }
        } Catch {
            [Console]::WriteLine("Error retrieving members for group $GroupId`: $_")
        }
    }

    Function Get-ResolvedGroupMembers {
        Param (
            [string[]]$GroupNames
        )

        $allMembers = @()
        ForEach ($groupName in $GroupNames) {
            [Console]::WriteLine("Resolving members for group: $groupName")
            Try {
                $groupId = (Get-MgBetaGroup -Filter "DisplayName eq '$groupName'").Id
                If ($groupId) {
                    $visited = [System.Collections.Generic.List[string]]::new()
                    $resolved = [System.Collections.Generic.List[object]]::new()
                    Get-TransitiveGroupMembersRecursive -GroupId $groupId -VisitedGroups ([ref]$visited) -ResolvedMembers ([ref]$resolved)
                    $allMembers += $resolved
                    [Console]::WriteLine("$($resolved.Count) members resolved from $groupName")
                } Else {
                    [Console]::WriteLine("Group not found: $groupName")
                }
            } Catch {
                [Console]::WriteLine("Error resolving group $groupName`: $_")
            }
        }
        Return $allMembers
    }

    $wufbGroupNames = @(
        'MEM-Win-Pol-WUfB-Insiders-Beta',
        'MEM-Win-Pol-WUfB-Insiders-Dev',
        'MEM-Win-Pol-WUfB-Insiders-Release-Preview',
        'MEM-Win-Pol-WUfB-Win10-Pilot',
        'MEM-Win-Pol-WUfB-Win10-Prod',
        'MEM-Win-Pol-WUfB-Win11-Pilot',
        'MEM-Win-Pol-WUfB-Win11-Prod'
    )
    $wufbGroupMembers = Get-ResolvedGroupMembers -GroupNames $wufbGroupNames

    $m365GroupNames = @(
        'MEM-Win-Pol-M365-Updates-Current-D',
        'MEM-Win-Pol-M365-Updates-Insiders-Beta-D',
        'MEM-Win-Pol-M365-Updates-Insiders-Preview-D',
        'MEM-Win-Pol-M365-Updates-Monthly-D',
        'MEM-Win-Pol-M365-Updates-Semi-Annual-D'
    )
    $m365GroupMembers = Get-ResolvedGroupMembers -GroupNames $m365GroupNames

    If (!(Test-Path -Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }

    $fileName = "$FileNamePrefix-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $outputPath = Join-Path $OutputFolder $fileName

    [Console]::WriteLine("Gathering list of pending Entra devices...")
    $pendingDevices = Get-MgBetaDevice -All -Filter "TrustType eq 'ServerAd'" |
        Where-Object { $_.ProfileType -ne "RegisteredDevice" -and (-not $_.AlternativeSecurityIds) }

    $ahQuery = @"
DeviceTvmSoftwareVulnerabilities
| where SoftwareVendor == 'microsoft'
| where SoftwareName == 'windows_11'
| where isnotempty(RecommendedSecurityUpdate)
| distinct DeviceId, RecommendedSecurityUpdate, RecommendedSecurityUpdateId, SoftwareName
| join kind=leftouter (
    DeviceInfo
    | where isnotempty(OSPlatform)
    | where OnboardingStatus == 'Onboarded'
    | where isnotempty(OSVersionInfo)
    | summarize arg_max(Timestamp, *) by DeviceId)
    on `$left.DeviceId == `$right.DeviceId
| summarize MissingKBs = make_set(RecommendedSecurityUpdate) by DeviceName
| extend TotalMissingKB = array_length(MissingKBs)
"@

    Try {
        $mdeResponse = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/security/runHuntingQuery" `
            -Body @{ Query = $ahQuery } `
            -ContentType "application/json"

        $mdeResults = $mdeResponse.Results
    } Catch {
        [Console]::WriteLine("Failed to retrieve Defender data: $_")
        $mdeResults = @()
    }

    $ahOfficeQuery = @"
DeviceTvmSoftwareInventory
| where SoftwareName == 'office'
| join kind=inner (
    DeviceInfo
    | where OnboardingStatus == 'Onboarded'
) on DeviceId
| summarize arg_max(Timestamp, *) by DeviceName
| project DeviceName, SoftwareVersion
"@

    Try {
        $officeResponse = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/security/runHuntingQuery" `
            -Body @{ Query = $ahOfficeQuery } `
            -ContentType "application/json"

        $officeResults = $officeResponse.Results
    } Catch {
        [Console]::WriteLine("Failed to retrieve M365 Apps version data: $_")
        $officeResults = @()
    }

    Switch ($PSCmdlet.ParameterSetName) {
        'FromCsv'   { $inputList = Import-Csv -Path $CsvPath | Select-Object -ExpandProperty $CsvColumnName }
        'FromText'  { $inputList = Get-Content -Path $TextFilePath }
        'Single'    { $inputList = @($ComputerName) }
    }

    # Split input list into batches of 10
    $deviceBatches = @()
    for ($i = 0; $i -lt $inputList.Count; $i += 10) {
        $deviceBatches += ,$inputList[$i..([Math]::Min($i+9, $inputList.Count - 1))]
    }

    # Create runspace pool
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 20)
    $runspacePool.Open()

    # Prepare shared results collection
    $syncResults = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

    # Create and start runspaces
    $runspaces = @()
    foreach ($batch in $deviceBatches) {
        foreach ($computerName in $batch) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            $powershell.AddScript({
                param(
                    $computerName, $SiteServer, $SiteCode,
                    $pendingDevices, $wufbGroupMembers, $m365GroupMembers,
                    $mdeResults, $officeResults, $sharedResults
                )

                $cemeteryStatus = "Unknown"
                $adEnabled = 'Unknown'
                $ouPath = "Unknown"
                $pingable = "No"
                $lastKnownIP = "None"
                $entraOID = "None"
                $entraDvcId = "None"
                $entraLastActivity = "None"
                $entraPending = "None"
                $entraWinGroupMember = "None"
                $entraM365GroupMember = "None"
                $intuneDvcId = "None"
                $intuneLastActivity = "None"
                $wlDvcConfig = 'Unknown'
                $wlM365Apps = 'Unknown'
                $wlWUfB = 'Unknown'
                $formattedIpAddressV4 = "None"
                $formattedWiredIPs = "None"
                $mdeTotalMissingKBs = "None"
                $mdeMissingKBNames = "None"
                $mdeM365AppsVersion = "None"
                $configMgrStatus = "No"
                $configMgrClientStatus = "No"
                $configMgrHAMembership = "No"

                Function Get-FallbackDC {
                    param (
                        [int]$MaxRetries = 3,
                        [int]$DelaySeconds = 2
                    )

                    For ($i = 1; $i -le $MaxRetries; $i++) {
                        Try {
                            $dc = ((Get-ADDomainController -Discover -NextClosestSite | Select-Object -ExpandProperty HostName) | Select-Object -First 1)
                            If ($dc -and $dc -isnot [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]) {
                                Return $dc
                            }
                        } Catch {
                            Write-Warning "Attempt $i`: Failed to discover fallback DC. Error: $_"
                        }

                        Start-Sleep -Seconds $DelaySeconds
                    }

                    Throw "Unable to discover a valid fallback DC after $MaxRetries attempts."
                }

                Function Invoke-WithRetry {
                    param (
                        [ScriptBlock]$Script,
                        [int]$MaxRetries = 3,
                        [int]$DelaySeconds = 2
                    )

                    For ($i = 1; $i -le $MaxRetries; $i++) {
                        Try {
                            Return & $Script
                        } Catch {
                            # If it's a known "Not In AD" case, don't retry — just bubble it up
                            If ($_.Exception -is [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]) {
                                Throw $_  # Let the outer catch handle it as "Not In AD"
                            }

                            Write-Warning "Attempt $i failed: $($_.Exception.Message)"
                            Start-Sleep -Seconds $DelaySeconds
                        }
                    }

                    Throw "All $MaxRetries attempts failed due to unexpected errors."
                }

                [Console]::WriteLine("Processing device: $computerName")

                Try {
                    [Console]::WriteLine("Querying AD for computer: $computerName")

                    $adComputer = Invoke-WithRetry {
                        Get-ADComputer -Identity $computerName -ErrorAction Stop
                    }

                    $cemeteryStatus = If ($adComputer.DistinguishedName -like "*OU=Cemetery*") { "Yes" } Else { "No" }
                    $adEnabled = If ($adComputer.Enabled -eq $true) { "Yes" } Else { "No" }
                    $ouPath = $adComputer.DistinguishedName
                    [Console]::WriteLine("Device '$computerName' found in AD. OU Path: $ouPath")
                } Catch {
                    $errorDetails = "Initial query failed for '$computerName'. "

                    Try {
                        $fallbackDC = Get-FallbackDC
                        $adComputer = Invoke-WithRetry {
                            Get-ADComputer -Identity $computerName -Server $fallbackDC -ErrorAction Stop
                        }

                        $cemeteryStatus = If ($adComputer.DistinguishedName -like "*OU=Cemetery*") { "Yes" } Else { "No" }
                        $adEnabled = If ($adComputer.Enabled -eq $true) { "Yes" } Else { "No" }
                        $ouPath = $adComputer.DistinguishedName
                        [Console]::WriteLine("Device '$computerName' found in AD via fallback DC: $fallbackDC. OU Path: $ouPath")
                    }
                    Catch {
                        if ($_.Exception -is [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]) {
                            $errorDetails += "Device not found in AD (ObjectNotFound)."
                            [Console]::WriteLine($errorDetails)
                            $ouPath = "Not In AD"
                            $cemeteryStatus = "Not In AD"
                            $adEnabled = "Not In AD"
                        }
                        else {
                            $fallbackError = $_.Exception.Message
                            $errorDetails += "Fallback DC query failed: $fallbackError"
                            [Console]::WriteLine($errorDetails)

                            $ouPath = "Error: $errorDetails"
                            $cemeteryStatus = "Error"
                            $adEnabled = "Error"
                        }
                    }
                }

                Try {
                    [Console]::WriteLine("Pinging device: $computerName")
                    $pingResult = Test-Connection -ComputerName $computerName -Count 1 -Quiet
                    If ($pingResult) {
                        $pingable = "Yes"
                        $resolvedIP = [System.Net.Dns]::GetHostAddresses($computerName) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
                        If ($resolvedIP) {
                            $lastKnownIP = $resolvedIP[0].IPAddressToString
                        }
                        [Console]::WriteLine("Device responded to ping. IP=$lastKnownIP")
                    } else {
                        [Console]::WriteLine("Device did not respond to ping. Attempting DNS resolution...")
                        Try {
                            $dnsResult = Resolve-DnsName -Name $computerName -Type A -ErrorAction Stop
                            $lastKnownIP = ($dnsResult | Select-Object -First 1).IPAddress
                            [Console]::WriteLine("DNS resolved. LastKnownIP=$lastKnownIP")
                        } catch {
                            [Console]::WriteLine("DNS resolution failed. No known IP.")
                        }
                    }
                } Catch {
                    [Console]::WriteLine("Error during ping or DNS resolution")
                }

                Try {
                    [Console]::WriteLine("Querying ConfigMgr remotely for device...")
                    $query = "SELECT Name, Client FROM SMS_R_System WHERE Name = '$computerName'"
                    $configMgrDevice = Invoke-Command -ComputerName $SiteServer -ScriptBlock {
                        param($query, $siteCode)
                        Get-WmiObject -Namespace "root\SMS\site_$siteCode" -Query $query
                    } -ArgumentList $query, $SiteCode

                    If ($configMgrDevice) {
                        $configMgrStatus = "Yes"
                        $configMgrClientStatus = If ($configMgrDevice.Client) { "Yes" } Else { "No" }

                        $CollectionID = 'COS020F0'
                        $membership = Get-WmiObject -Namespace "root\SMS\site_$SiteCode" `
                                                    -ComputerName $SiteServer `
                                                    -Class "SMS_FullCollectionMembership" `
                                                    -Filter "CollectionID = '$CollectionID' AND Name = '$computerName'"

                        If ($membership) {
                            [Console]::WriteLine("$computerName exists in collection $CollectionID")
                            $configMgrHAMembership = "Yes"
                        } Else {
                            [Console]::WriteLine("$computerName is NOT in collection $CollectionID")
                            $configMgrHAMembership = "No"
                        }
                    }
                } Catch {
                    [Console]::WriteLine("Error querying ConfigMgr remotely")
                }

                Try {
                    [Console]::WriteLine("Searching Entra ID for matching device...")
                    $entraDevices = Get-MgBetaDevice -Filter "startswith(DisplayName,'$computerName')"
                    $targetDevice = $entraDevices | Where-Object { $_.TrustType -eq "ServerAd" }

                    If ($targetDevice) {
                        $entraOID   = $targetDevice.Id
                        $entraDvcId = $targetDevice.DeviceId
                        $entraLastActivity = $targetDevice.ApproximateLastSignInDateTime

                        $entraPending = If ($pendingDevices | Where-Object { $_.Id -eq $entraOID }) { "Yes" } Else { "No" }
                        $entraWinGroupMember = If ($wufbGroupMembers | Where-Object { $_.Id -eq $entraOID }) { "Yes" } Else { "No" }
                        $entraM365GroupMember = If ($m365GroupMembers | Where-Object { $_.Id -eq $entraOID }) { "Yes" } Else { "No" }

                        [Console]::WriteLine("Entra device found. LastActivity=$entraLastActivity, Pending=$entraPending, WUfB=$entraWinGroupMember, M365=$entraM365GroupMember")
                    } Else {
                        [Console]::WriteLine("No matching Entra device found")
                    }
                } Catch {
                    [Console]::WriteLine("Error querying Entra ID")
                }

                Try {
                    [Console]::WriteLine("Checking Intune for device...")
                    $rawDevices = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(DeviceName,'$computerName')" -All
                    $intuneDevices = if ($rawDevices.Value) { $rawDevices.Value } else { @($rawDevices) }

                    $matchedIntuneDevices = @(
                        $intuneDevices | Where-Object { $_.DeviceName -eq $computerName } | Sort-Object LastSyncDateTime -Descending
                    )

                    If ($matchedIntuneDevices -and $matchedIntuneDevices.Count -gt 0) {
                        $latestDevice = $matchedIntuneDevices[0]
                        $intuneDvcId = $latestDevice.Id
                        $intuneLastActivity = $latestDevice.LastSyncDateTime

                        $hardwareInfo = Get-MgBetaDeviceManagementManagedDevice -ManagedDeviceId $intuneDvcId -Property "hardwareInformation"
                        $workloadInfo = Get-MgBetaDeviceManagementManagedDevice -ManagedDeviceId $intuneDvcId -Property "ConfigurationManagerClientEnabledFeatures"

                        # Grab IP info
                        $ipAddressV4 = $hardwareInfo.HardwareInformation.IPAddressV4
                        $wiredIPs = $hardwareInfo.HardwareInformation.WiredIPv4Addresses

                        $formattedIpAddressV4 = If ($ipAddressV4) { $ipAddressV4 -join ";" } else { "None" }
                        $formattedWiredIPs = If ($wiredIPs) { $wiredIPs -join ";" } else { "None" }

                        # Grab ConfigMgr/Intune workload info
                        $wlDvcConfig = If ($workloadInfo.ConfigurationManagerClientEnabledFeatures.DeviceConfiguration) { "Yes" } else { "No" }
                        $wlM365Apps  = If ($workloadInfo.ConfigurationManagerClientEnabledFeatures.OfficeApps) { "Yes" } else { "No" }
                        $wlWUfB      = If ($workloadInfo.ConfigurationManagerClientEnabledFeatures.WindowsUpdateForBusiness) { "Yes" } else { "No" }

                        [Console]::WriteLine("Found Intune device: $intuneDvcId, LastSync=$intuneLastActivity, IPAddressV4=$formattedIpAddressV4, WiredIPv4Addresses=$formattedWiredIPs, WL-DvcConfig=$wlDvcConfig, WL-M365Apps=$wlM365Apps, WL-WUfB=$wlWUfB")
                    } Else {
                        [Console]::WriteLine("No matching Intune device found")
                    }
                } Catch {
                    [Console]::WriteLine("Error querying Intune")
                }

                $mdeMatch = $mdeResults | Where-Object { $_.DeviceName -match "^$computerName(\.|$)" }
                If ($mdeMatch) {
                    $mdeTotalMissingKBs = $mdeMatch.TotalMissingKB
                    $mdeMissingKBNames = ($mdeMatch.MissingKBs -join ";") -replace ",", ";"
                    [Console]::WriteLine("Defender info found: $mdeTotalMissingKBs missing KBs")
                } Else {
                    [Console]::WriteLine("No Defender info found for device")
                }

                $m365AppsMatch = $officeResults | Where-Object { $_.DeviceName -match "^$computerName(\.|$)" }
                If ($m365AppsMatch) {
                    $mdeM365AppsVersion = $m365AppsMatch.SoftwareVersion
                    [Console]::WriteLine("M365 Apps version found: $mdeM365AppsVersion")
                } Else {
                    [Console]::WriteLine("No M365 Apps version info found for device")
                }

                $sharedResults.Add([pscustomobject]@{
                    'DeviceName'                = $computerName
                    'AD-Cemetery'               = $cemeteryStatus
                    'AD-Enabled'                = $adEnabled
                    'AD-OUPath'                 = $ouPath
                    'OnPrem-Ping'               = $pingable
                    'OnPrem-LastKnownIP'        = $lastKnownIP
                    'Entra-ObjectId'            = $entraOID
                    'Entra-DeviceId'            = $entraDvcId
                    'Entra-LastActivity'        = $entraLastActivity
                    'Entra-Pending'             = $entraPending
                    'Entra-WUfBGroupMember'     = $entraWinGroupMember
                    'Entra-M365GroupMember'     = $entraM365GroupMember
                    'Intune-DeviceId'           = $intuneDvcId
                    'Intune-LastActivity'       = $intuneLastActivity
                    'Intune-IPAddressV4'        = $formattedIpAddressV4
                    'Intune-WiredIPv4Addresses' = $formattedWiredIPs
                    'Intune-WL-DeviceConfig'    = $wlDvcConfig
                    'Intune-WL-M365Apps'        = $wlM365Apps
                    'Intune-WL-WUfB'            = $wlWUfB
                    'MDE-TotalMissingWinKBs'    = $mdeTotalMissingKBs
                    'MDE-MissingWinKBNames'     = $mdeMissingKBNames
                    'MDE-M365AppsVersion'       = $mdeM365AppsVersion
                    'ConfigMgr-Visible'         = $configMgrStatus
                    'ConfigMgr-Client'          = $configMgrClientStatus
                    'ConfigMgr-HAMembership'    = $configMgrHAMembership
                })
            }).AddArgument($computerName).AddArgument($SiteServer).AddArgument($SiteCode).AddArgument($pendingDevices).AddArgument($wufbGroupMembers).AddArgument($m365GroupMembers).AddArgument($mdeResults).AddArgument($officeResults).AddArgument($syncResults)

            $asyncHandle = $powershell.BeginInvoke()
            $runspaces += [PSCustomObject]@{
                Pipe   = $powershell
                Status = $asyncHandle
            }
        }
    }

    foreach ($r in $runspaces) {
        $r.Pipe.EndInvoke($r.Status)
        $r.Pipe.Dispose()
    }

    $runspacePool.Close()
    $runspacePool.Dispose()

    [Console]::WriteLine("Exporting results to: $outputPath")
    $syncResults | Export-Csv -Path $outputPath -NoTypeInformation
    [Console]::WriteLine("All done. Results saved!")
    $syncResults | Format-List
}