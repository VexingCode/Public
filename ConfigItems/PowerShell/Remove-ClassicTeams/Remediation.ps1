################################################################################
# MIT License
#
# Copyright (c) 2024 Microsoft and Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 
# Filename: UninstallClassicTeams
# Version: 1.1.9
# Description: Script to cleanup old teams and corresponding regkeys for all users on machine.
#################################################################################


param(
    [Parameter()]
    [switch]$SkipAllArtifactsRemoval
)

$applicationDefinitions = @(
    @{
        Name="Teams"
        DisplayName="Teams"
        Publisher="Microsoft"
        Exe="teams"
        IDs=@(
            ### Array of product ids to look for - unimplemented
            "731F6BAA-A986-45A4-8936-7C3AAAAA760B",
            "{731F6BAA-A986-45A4-8936-7C3AAAAA760B}"
        )
        RegistryKeys=@(
            ### Array of registry keys to match
            ### If a registry entry starts with the hive name the match is performed using StartsWith() - case insensitive 'hkey_\FooBar...' == 'hkey_\foobar...'
            ### If a registry entry lacks the hive name then the match is performed using EndsWith() - case insensitive '...FooBar' == '...foobar'
            "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
        )
        CleanUp=@(
            ### Array of cleanup steps
            @{
                RunUninstall=$true
                RemoveRegistryKeys=$true
                RemoveDirectory=$true
            }
        )
    }
)

$ScriptResult = @{
    NumProfiles = 0
	NumApplicationsFound = 0
	NumApplicationsRemoved = 0
    FindApplicationProfilesLoadedSuccessfully = 0
	FindApplicationProfilesLoadedFailed = 0
    FindApplicationProfilesUnloadedSuccessfully = 0
	FindApplicationProfilesUnloadedFailed = 0
    FindApplicationInstallationFound = 0
	RemoveApplicationProfilesLoadedSuccessfully = 0
	RemoveApplicationProfilesLoadedFailed = 0
	RemoveApplicationNumProfilesUnloadedSuccessfully = 0
	RemoveApplicationProfilesUnloadedFailed = 0
	RemoveApplicationUninstallionPerformed = 0
	StaleFileSystemEntryDeleted = 0
	AppDataEntryDeleted = 0
	StaleRegkeyEntryDeleted = 0
	MachineWideInstallerStaleRegkeyEntryDeleted = 0
	TeamsMeetingAddinDeleted = 0
	TeamsWideInstallerRunKeyDeleted = 0
	StaleUserAssociationRegkeyEntryDeleted = 0
	StaleSquirrelRegkeyEntryDeleted = 0
	RemovedBackupMsiInstaller = 0
	RemovedBackupMsiInstallerRegkeys = 0
	StaleVDITMAEntryDeleted = 0
	StaleVDIPresenceAddinEntryDeleted = 0
	SquirrelTempDeleted = 0
}

# Function that creates the unique file path
function Get-UniqueFilename {
    param (
        [string]$BaseName,
        [string]$Extension = "txt",
        [string]$DateTimeFormat = "yyyyMMddHHmmss"
    )
    
    # Get the current date and time in the specified format
    $timestamp = (Get-Date).ToString($DateTimeFormat)
    
    # Combine the base name, timestamp, and extension
    $uniqueFilename = "$BaseName-$timestamp.$Extension"
    
    # Return the unique filename
    return $uniqueFilename
}

$Logfile = Get-UniqueFilename("$($ENV:SystemDrive)\Windows\Temp\Classic_Teams_Uninstallation")

function write-teams-log {
	Param ([string]$LogString)
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$LogMessage = "$Stamp $LogString"
	Add-content $LogFile -value $LogMessage
}


# Function to find SID for user
function Get-SIDFromAlias {
    param (
        [string]$userAlias
    )
    
    try {
        # Create a NTAccount object from the user alias
        $ntAccount = New-Object System.Security.Principal.NTAccount($userAlias)
        
        # Translate NTAccount to SecurityIdentifier
        $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
        
        # Output the SID
        return $sid.Value
    }
    catch {
        Write-Error "Failed to convert alias to SID: $_"
    }
}

# Function to find application installed as per specifications for all user profiles
function Find-WindowsApplication {
    param(
        [Parameter(Mandatory)]
        [psobject[]]$ApplicationDefinitions = $null,
        [switch]$AllUsers
    )

        
    if (
        (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) -or
        (-not ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")))
    )
    {
        write-teams-log "Warning: $($MyInvocation.MyCommand): Running without elevated permissions will reduce functionality"
    }


    write-teams-log "$($MyInvocation.MyCommand): Searching for software..."
    $installedSoftware = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue
    $installedApps = Get-AppXPackage -ErrorAction SilentlyContinue
    $installed32bitComponents = @(Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
    $installed64bitComponents = @(Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
    $systemEnvironment = $(Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -ErrorAction SilentlyContinue)
    $userComponents = @{}
    
    $foundApplicationList = @()
    $foundApplicationEntry = @{
        AppDefinition=$null
        Location=@{
            Software=@()
            Apps=@()
            Components=@{}
        }
        Found=$false
    }

    
    $componentSourceList = @{}

    $componentSourceList["SYSTEM"] = [psobject]@{
        Installed32BitComponents=$installed32bitComponents
        Installed64BitComponents=$installed64bitComponents
        Environment=$systemEnvironment
        RegFile=$null
        Username=$null
    }

    $componentSourceList["CURRENTUSER"] = [psobject]@{
        Installed32BitComponents=@(Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
        Installed64BitComponents=@(Get-ChildItem "HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
        Environment=$(Get-ItemProperty "HKCU:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -ErrorAction SilentlyContinue)
        RegFile=$null
        Username="$($env:USERNAME)"
    }

    if ($AllUsers)
    {
        write-teams-log "$($MyInvocation.MyCommand): Getting list of installed software for each user..."
        
        foreach ($userDirectory in @(Get-ChildItem "$($ENV:SystemDrive)\users" -ErrorAction SilentlyContinue))
        {
            if ($userDirectory -ne $null)
            {
                $userName = "$($userDirectory.Name.ToLower())"
				$ScriptResult.NumProfiles++
                
                # write-teams-log "$($MyInvocation.MyCommand): Looking at user $($username) profile..."
				# write-teams-log "$($MyInvocation.MyCommand): Looking at user profile..."

                $userComponents["$($userName)"] = [psobject]@{
                    Installed32BitComponents=$null
                    Installed64BitComponents=$null
                    Environment=$null
                    RegFile=$null
                    Username=$null
                }
                $componentSourceList["$($userName)"] = $userComponents["$($userName)"]

                $process = $null
                try
                {
                    $command = "`"REG LOAD `"`"HKLM\$($userName)`"`" `"`"$($userDirectory.FullName)\NTUSER.DAT`"`""
                    $process = Start-Process "$($env:ComSpec)" -ArgumentList @("/c","$($command)") -Wait -WindowStyle Hidden  -PassThru
                    if ($process.ExitCode -eq 0)
                    {
						### good
						$ScriptResult.FindApplicationProfilesLoadedSuccessfully++
                    } else
                    {
						### ungood
						$ScriptResult.FindApplicationProfilesLoadedFailed++
						write-teams-log "Warning: $($MyInvocation.MyCommand): Profile loading failed with exit code $($process.ExitCode)"
                    }
                }
                catch
                {
					### ignore
					$ScriptResult.FindApplicationProfilesLoadedFailed++
					write-teams-log "Warning: $($MyInvocation.MyCommand): Profile loading caught exception. An error occurred: $_"
                }
                $userRegistry = Get-Item "HKLM:\$($userName)" -ErrorAction SilentlyContinue
                if ($userRegistry -ne $null)
                {
                    $userComponents["$($userName)"].RegFile="$($userDirectory.FullName)\NTUSER.DAT"
                    $userComponents["$($userName)"].Environment=$(Get-ItemProperty "HKLM:\$($userName)\Environment" -ErrorAction SilentlyContinue)
                    $userComponents["$($userName)"].Installed32BitComponents=@(Get-ChildItem "HKLM:\$($userName)\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
                    $userComponents["$($userName)"].Installed64BitComponents=@(Get-ChildItem "HKLM:\$($userName)\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
                    $componentSourceList["$($userName)"] = $userComponents["$($userName)"]
					
					$process = $null
					try
					{
						$command = "`"REG UNLOAD `"`"HKLM\$($userName)`"`""
						$process = Start-Process "$($env:ComSpec)" -ArgumentList @("/c","$($command)") -Wait -WindowStyle Hidden  -PassThru
						if ($process.ExitCode -eq 0)
						{
							### good
							$ScriptResult.FindApplicationProfilesUnloadedSuccessfully++
						} else
						{
							### ungood
							$ScriptResult.FindApplicationProfilesUnloadedFailed++
							write-teams-log "$($MyInvocation.MyCommand): Profile unloading failed with exit code $($process.ExitCode)"
						}
					}
					catch
					{
						### ignore
						$ScriptResult.FindApplicationProfilesUnloadedFailed++
						write-teams-log "$($MyInvocation.MyCommand): Profile loading caught exception. An error occurred: $_"
					}
                }
            }
        }
    }

    foreach ($appDef in $ApplicationDefinitions)
    {
        if ($appDef -ne $null)
        {
            $foundApplicationEntry = @{
                AppDefinition=$appDef
                Location=@{
                    Software=@()
                    Apps=@()
                    Components=@{}
                    Files=@()
                }
                Found=$false
            }

            if ($appDef.RegistryKeys -ne $null)
            {
                if ($appDef.RegistryKeys.Count -gt 0)
                {
                    
                    ### search components
                    foreach ($componentSource in $componentSourceList.Keys)
                    {
                        ### search each location
                        $currentRegFile = $($componentSourceList["$($componentSource)"].RegFile)
                        $currentSource = $componentSource
                        $currentRegKeys = @()

                        if ($componentSourceList["$($componentSource)"] -ne $null)
                        {
                            if ($componentSourceList["$($componentSource)"].Installed32BitComponents -ne $null)
                            {
                                if ($componentSourceList["$($componentSource)"].Installed32BitComponents.Count -gt 0)
                                {
                                    $currentRegKeys += @($componentSourceList["$($componentSource)"].Installed32BitComponents)
                                }
                            }
                            if ($componentSourceList["$($componentSource)"].Installed64BitComponents -ne $null)
                            {
                                if ($componentSourceList["$($componentSource)"].Installed64BitComponents.Count -gt 0)
                                {
                                    $currentRegKeys += @($componentSourceList["$($componentSource)"].Installed64BitComponents)
                                }
                            }
                        }
                        
                        for ($c = 0; $c -lt $currentRegKeys.Count; $c++)
                        {
                            $regList = @($currentRegKeys[$c])
                            for ($x = 0; $x -lt $regList.Count; $x++)
                            {
                                $appRegKey = $($regList[$x].PSPath.Replace('Microsoft.PowerShell.Core\Registry::',''))

                                for ($r = 0; $r -lt $appDef.RegistryKeys.Count; $r++)
                                {
                            
                                    $foundEntry = $false
                                    if ($appDef.RegistryKeys[$r].StartsWith("HKEY_"))
                                    {
                                        if ($appRegKey.ToLower().StartsWith($appDef.RegistryKeys[$r].ToLower()))
                                        {
                                            ### found
                                            $foundEntry = $true
                                        }
                                    } else
                                    {
                                        if ($appRegKey.ToLower().EndsWith($appDef.RegistryKeys[$r].ToLower()))
                                        {
                                            ### found
                                            $foundEntry = $true
                                        }
                                    }
                            
                                    if ($foundEntry -eq $true)
                                    {                                    
                                        write-teams-log "$($MyInvocation.MyCommand): Found application '$($appDef.Name)', adding in found application list"

										$componentKey = "$($regList[$x].DisplayName)" + ":" + "$($currentSource)"
                                        if ($foundApplicationEntry.Location.Components["$($componentKey)"] -eq $null)
                                        {
											$ScriptResult.FindApplicationInstallationFound++
                                            $foundApplicationEntry.Location.Components["$($componentKey)"] = @{
                                                Component=$($regList[$x])
                                                ComponentSource=$($currentSource)
                                                RegistryKeys=@()
                                                RegFile=$currentRegFile
                                            }
											
											$foundApplicationEntry.Location.Components["$($componentKey)"].RegistryKeys += $appRegKey
											$foundApplicationEntry.Found = $true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if ($foundApplicationEntry -ne $null)
            {
                if ($foundApplicationEntry.Found -eq $true)
                {
                    $foundApplicationList += $foundApplicationEntry
                }
            }
        }
    }

    return @($foundApplicationList)
}


# Function to remove application from the machine for all user profiles
# If application is already running, process shall be killed
# Uninstallation for user profiles is done based on Uninstall string
function Remove-WindowsApplication {
    param(
        [Parameter(Mandatory)]
        [psobject[]]$Applications = $null
    )

        
    if (
        (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) -or
        (-not ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")))
    )
    {
        write-teams-log "Warning: $($MyInvocation.MyCommand): Running without elevated permissions will reduce functionality"
    }


    write-teams-log "$($MyInvocation.MyCommand): Removing application(s)..."
	write-teams-log "-------------------"
    
    $removedApplicationList = $null
    $removedApplicationEntry = @{
        AppDefinition=$null
        Successful=$false
        Error=$null
    }

    if ($Applications)
    {
        $removedApplicationList = @()

		for ($a = 0; $a -lt $Applications.Count; $a++)
		{
                if ($Applications[$a] -ne $null)
                {
                    
                    if ([string]::IsNullOrEmpty($Applications[$a].AppDefinition.Exe) -eq $false)
                    {
                        ### look for running process
                        $processList = @(Get-Process -Name $($Applications[$a].AppDefinition.Exe) -ErrorAction SilentlyContinue)
                        if ($processList -ne $null)
                        {
                            if ($processList.Count -gt 0)
                            {
                                write-teams-log "$($MyInvocation.MyCommand): Stopping existing processes..." 
                                @($processList).Kill()
                            }
                        }
                    }

                    if ($Applications[$a].Found -eq $true)
                    {
                        $appEntry = $Applications[$a]
                        
                        if ($appEntry.AppDefinition -ne $null)
                        {
                            if ($appEntry.AppDefinition.CleanUp -ne $null)
                            {
                                write-teams-log "$($MyInvocation.MyCommand): Removing application '$($appEntry.AppDefinition.Name)'..."
                                if ($appEntry.Location -ne $null)
                                {
									if (
										($appEntry.Location.Apps) -or 
										($appEntry.Location.Components.Keys) -or 
										($appEntry.Location.Software) -or
										($appEntry.Location.Files)
									)
									{
										$removedApplicationEntry = $null

										if ($appEntry.Location.Components.Keys.Count -gt 0)
										{
											foreach ($componentName in $appEntry.Location.Components.Keys)
											{
												$componentObj = $($appEntry.Location.Components["$($componentName)"])
												if ($componentObj -ne $null)
												{
													if ($componentObj.Component -ne $null)
													{
														# write-teams-log "$($MyInvocation.MyCommand): Removing component for user..."

														if ([string]::IsNullOrEmpty($componentObj.Component.InstallLocation) -eq $false)
														{
															### have install path
															$installDir = Get-Item "$($componentObj.Component.InstallLocation)" -ErrorAction SilentlyContinue
															if ($installDir -ne $null)
															{
																### have actual path
																if ($appEntry.AppDefinition.CleanUp.RunUninstall -eq $true)
																{
																	$uninstallCommand = "$($componentObj.Component.UninstallString)"

																	if ([string]::IsNullOrEmpty($componentObj.Component.QuietUninstallString) -eq $false)
																	{
																		$uninstallCommand = "$($componentObj.Component.QuietUninstallString)"
																	}

																	# write-teams-log "Uninstall command : $uninstallCommand"
																	if ([string]::IsNullOrEmpty($uninstallCommand) -eq $false)
																	{
																		### Run uninstall
																		write-teams-log "$($MyInvocation.MyCommand): Running component uninstall..."

																		Start-Process "$($env:ComSpec)" -ArgumentList @("/c","$($uninstallCommand)") -Verb RunAs -Wait -WindowStyle Hidden
																		$ScriptResult.RemoveApplicationUninstallionPerformed++
																	} else
																	{
																		write-teams-log "Warning: $($MyInvocation.MyCommand): Component has no uninstall command."
																	}
																}

																### remove app path
																if ($appEntry.AppDefinition.CleanUp.RemoveDirectory -eq $true)
																{
																	write-teams-log "$($MyInvocation.MyCommand): Removing component directories..."
																	$ignore = Remove-Item "$($installDir.FullName)" -Recurse -Force -ErrorAction SilentlyContinue
																}

															} else
															{
																write-teams-log "Warning: $($MyInvocation.MyCommand): Component install path can't be found."
															}
														}


														### remove registry key(s)
														if ($appEntry.AppDefinition.CleanUp.RemoveRegistryKeys -eq $true)
														{                                                                    
															$regUser = $componentObj.ComponentSource

															if ($componentObj.RegistryKeys -ne $null)
															{
																if ($componentObj.RegistryKeys.Count -gt 0)
																{
																	write-teams-log "$($MyInvocation.MyCommand): Removing component registry key(s)..."

																	if ($componentObj.RegFile -ne $null)
																	{
																		### Load user's registry file
																		$regFile = $componentObj.RegFile

																		try
																		{
																			$output = Start-Process "$($env:ComSpec)" -ArgumentList @("/c","""REG LOAD """"HKLM\$($regUser)"""" """"$($regFile)"""" 1>NUL 2>NUL") -Wait -WindowStyle Hidden  -PassThru
																			$ScriptResult.RemoveApplicationProfilesLoadedSuccessfully++
																		}
																		catch
																		{
																			### ignore
																			$ScriptResult.RemoveApplicationProfilesLoadedFailed++
																			write-teams-log "Warning: $($MyInvocation.MyCommand): Profile loading caught exception. An error occurred: $_"
																		}
																	}

																	### Remove registry key(s)
																	for ($r = 0; $r -lt $componentObj.RegistryKeys.Count; $r++)
																	{
																		$regKey = "$($componentObj.RegistryKeys[$r].Replace('Microsoft.PowerShell.Core\Registry::',''))"
																		$ignore = Remove-Item "registry::$($regKey)" -Recurse -Force -ErrorAction SilentlyContinue
																	}

																	if ($componentObj.RegFile -ne $null)
																	{                                                                    
																		### Unload user's registry file
																		try
																		{
																			$output = Start-Process "$($env:ComSpec)" -ArgumentList @("/c","""REG UNLOAD """"HKLM\$($userName)"""" 1>NUL 2>NUL") -Wait -WindowStyle Hidden
																			$ScriptResult.RemoveApplicationNumProfilesUnloadedSuccessfully++
																		}
																		catch
																		{
																			### ignore
																			$ScriptResult.RemoveApplicationProfilesUnloadedFailed++
																			write-teams-log "Warning: $($MyInvocation.MyCommand): Profile unloading caught exception. An error occurred: $_"
																		}
																	}
																} else
																{
																	write-teams-log "Warning: $($MyInvocation.MyCommand): Component has no registry key(s)."
																}
															} else
															{
																write-teams-log "Warning: Warning: $($MyInvocation.MyCommand): Component has no registry key(s)."
															}
														}
													}
												}
											}
										}

										$removedApplicationEntry = @{
											AppDefinition=$appEntry.AppDefinition
											Successful=$true
											Error=$null
										}


										if ($removedApplicationEntry -ne $null)
										{
											$removedApplicationList += $removedApplicationEntry
										}
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }

    if ($removedApplicationList -ne $null)
    {
        return @($removedApplicationList)
    }

    return $removedApplicationList
}

function Remove-DirectoryRecursively {
    param(
        [string]$dirPath
    )

    if (Test-Path $dirPath) {
        Remove-Item -Path $dirPath -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    } else {
        return $false
    }
}

# Function to remove the stale user name entries whose entry is not present in HKLM/:{$username)
# Also cleans the Appdata folder
Function Remove-TeamsStaleUserProfileFileSystemEntries {
	$userProfiles = (Get-ChildItem "$($ENV:SystemDrive)\Users" -Directory -Exclude "Public", "Default", "Default User").FullName
	
	foreach($profile in $userProfiles) {
		# Removing the complete old teams directory
		$userProfileTeamsPath = Join-Path -Path $profile -ChildPath "\AppData\Local\Microsoft\Teams\"
		$result = Remove-DirectoryRecursively -dirPath $userProfileTeamsPath
		if ($result) {
			$ScriptResult.StaleFileSystemEntryDeleted++
			write-teams-log "Deleted stale file system entry successfully."
		}
		
		$userProfileTeamsAppDataPath = Join-Path -Path $profile -ChildPath "\AppData\Roaming\Microsoft\Teams"
		$result2 = Remove-DirectoryRecursively -dirPath $userProfileTeamsAppDataPath
		if ($result2) {
			$ScriptResult.AppDataEntryDeleted++
			write-teams-log "Deleted stale App data file system entry successfully."
		}
		
		$userProfileSquirrelTempPath = Join-Path -Path $profile -ChildPath "\AppData\Local\Microsoft\SquirrelTemp"
		$result3 = Remove-DirectoryRecursively -dirPath $userProfileSquirrelTempPath
		if ($result3) {
			$ScriptResult.SquirrelTempDeleted++
			write-teams-log "Deleted SquirrelTemp successfully."
		}
	}
}

# Function to remove TMA entries
Function Remove-TeamsMeetingAddin {
	$userProfiles = (Get-ChildItem "$($ENV:SystemDrive)\Users" -Directory -Exclude "Public", "Default", "Default User").FullName
	
	foreach($profile in $userProfiles) {
		# Removing the complete old teams directory
		$userProfileTMAPath = Join-Path -Path $profile -ChildPath "\AppData\Local\Microsoft\TeamsMeetingAddin"
		$result = Remove-DirectoryRecursively -dirPath $userProfileTMAPath
		if ($result) {
			$ScriptResult.TeamsMeetingAddinDeleted++
			write-teams-log "Deleted TMA successfully."
		}
	}
}

# Function to remove only stale regkey entries from the HKEY_USERS
Function Remove-TeamsStaleRegKeys {
	$subkeys = (Get-ChildItem -Path "registry::HKEY_USERS"  -Exclude .DEFAULT).Name
	
	foreach($subkey in $subkeys) {
		$regkey = "registry::$subkey\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
		if (Test-Path $regkey) {
			$ignore = Remove-Item "$regKey" -Recurse -Force -ErrorAction SilentlyContinue
			write-teams-log "Deleted stale regkey entry from HKEY_USERS successfully."
			$ScriptResult.StaleRegkeyEntryDeleted++
		}
		
		# Very Rare scenario, if classic teams is chosen delibrately by user as default for msteams.
		$associationKeyPath = "registry::$subkey\SOFTWARE\Microsoft\Office\Teams\Capabilities\URLAssociations"
		if (Test-Path $associationKeyPath) {
			$res = Get-ItemProperty -Path $associationKeyPath -Name 'msteams' -ErrorAction SilentlyContinue
			
			if ($res -ne $null) {
				$ignore = Remove-ItemProperty -Path $associationKeyPath -Name 'msteams' -ErrorAction SilentlyContinue
				write-teams-log "Deleted URL association msteams entry."
				$ScriptResult.StaleUserAssociationRegkeyEntryDeleted++
			}
		}
		
		$squirrelKeyPath = "registry::$subkey\Software\Microsoft\Windows\CurrentVersion\Run"
		if (Test-Path $squirrelKeyPath) {
			$res = Get-ItemProperty -Path $squirrelKeyPath -Name 'com.squirrel.Teams.Teams' -ErrorAction SilentlyContinue
			
			if ($res -ne $null) {
				$ignore = Remove-ItemProperty -Path $squirrelKeyPath -Name 'com.squirrel.Teams.Teams' -ErrorAction SilentlyContinue
				write-teams-log "Deleted stale squirrel regkey entry."
				$ScriptResult.StaleSquirrelRegkeyEntryDeleted++
			}
		}
	}
}

function Remove-TeamsWideInstallerRunKey {
    param (
        [string]$valueName
    )

    $regPathWOW6432Node = "registry::HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $regPathWOW6432Node) {
        $regValue = Get-ItemProperty -Path $regPathWOW6432Node -Name $valueName -ErrorAction SilentlyContinue

        if ($regValue -ne $null) {
            Remove-ItemProperty -Path $regPathWOW6432Node -Name $valueName -Force
            $ScriptResult.TeamsWideInstallerRunKeyDeleted++
            write-teams-log "Teams wide installer uninstall step. The registry value '$valueName' has been deleted."
        } else {
            write-teams-log "Teams wide installer uninstall step. The registry value '$valueName' does not exist."
        }
    }

    $regPath = "registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $regPath) {
        $regValue = Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue

        if ($regValue -ne $null) {
            Remove-ItemProperty -Path $regPath -Name $valueName -Force
            $ScriptResult.TeamsWideInstallerRunKeyDeleted++
            write-teams-log "Teams wide installer uninstall step. The registry value '$valueName' has been deleted."
        } else {
            write-teams-log "Teams wide installer uninstall step. The registry value '$valueName' does not exist."
        }
    }
}

Function Remove-vdiCleanup {
	$processorArchitecture = $env:PROCESSOR_ARCHITECTURE
	
	$tmaPath = "${Env:ProgramFiles(x86)}\Microsoft\TeamsMeetingAddin"
	$presenceAddinPath = "${Env:ProgramFiles(x86)}\Microsoft\TeamsPresenceAddin"
	if ($processorArchitecture -eq 'x86') {
		$tmaPath = "${Env:ProgramFiles}\Microsoft\TeamsMeetingAddin"
		$presenceAddinPath = "${Env:ProgramFiles}\Microsoft\TeamsPresenceAddin"
	}
		
	$result = Remove-DirectoryRecursively -dirPath $tmaPath
	if ($result) {
		$ScriptResult.StaleVDITMAEntryDeleted++
		write-teams-log "Deleted stale tma file system entry for vdi successfully."
	}
	
	$result = Remove-DirectoryRecursively -dirPath $presenceAddinPath
	if ($result) {
		$ScriptResult.StaleVDIPresenceAddinEntryDeleted++
		write-teams-log "Deleted stale presence add-in file system entry for vdi successfully."
	}
}	

Function Remove-TeamsWideInstallerUninstallKey {
	$processorArchitecture = $env:PROCESSOR_ARCHITECTURE
	
	# Determine and output architecture
	if ($processorArchitecture -eq 'AMD64') {
		$regkey = "registry::HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{731F6BAA-A986-45A4-8936-7C3AAAAA760B}"
		if (Test-Path $regkey) {
			$ignore = Remove-Item "$regKey" -Recurse -Force -ErrorAction SilentlyContinue
			write-teams-log "Deleted machine wide installer uninstall keys"
			$ScriptResult.MachineWideInstallerStaleRegkeyEntryDeleted++
		}
	} elseif ($processorArchitecture -eq 'x86') {
		$regkey = "registry::HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{39AF0813-FA7B-4860-ADBE-93B9B214B914}"
		if (Test-Path $regkey) {
			$ignore = Remove-Item "$regKey" -Recurse -Force -ErrorAction SilentlyContinue
			write-teams-log "Deleted machine wide installer uninstall keys"
			$ScriptResult.MachineWideInstallerStaleRegkeyEntryDeleted++
		}
	}
}

# Function to remove backup msi Teams machine wide installer
Function Remove-TeamsMachineWideBackupMsiInstaller {
	$regkey = "registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData"
	
	# Get all subkeys and values
	$items = Get-ChildItem -Path $regkey
	foreach ($item in $items) {
		if ($item.PSIsContainer) {
			$tempRegPath =  Join-Path "registry::" $item  			
			$regPath = Join-Path $tempRegPath "Products\AAB6F137689A4A549863C7A3AAAA67B0\InstallProperties"

			if (Test-Path $regPath) {				
				$res = Get-ItemProperty -Path $regPath -Name 'LocalPackage' -ErrorAction SilentlyContinue
				if ($res -ne $null) {
					if (Test-Path $res.LocalPackage) {
						Remove-Item -Path $res.LocalPackage -Force
						$ScriptResult.RemovedBackupMsiInstaller++
					}
				}
				
				$regkeyToRemove = Join-Path $tempRegPath "Products\AAB6F137689A4A549863C7A3AAAA67B0"
				$ignore = Remove-Item "$regkeyToRemove" -Recurse -Force -ErrorAction SilentlyContinue
				$ScriptResult.RemovedBackupMsiInstallerRegkeys++
			}			
		}
	}
}

#Function to remove PatchCache files
Function Remove-PatchCacheFiles{
	$patchCachePaths = @(
		"C:\Windows\Installer\`$PatchCache$`\Managed\AD7E5E9D92C699247949F5DDF5A4D661\",
		"C:\Windows\Installer\`$PatchCache$`\Managed\3180FA93B7AF0684DAEB399B2B419B41\"
	)
	 
	# Loop through each path and delete if it exists
	foreach ($path in $patchCachePaths) {
		if (Test-Path $path) {
			try {
				Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
				write-teams-log "Deleted: $path"
			} catch {
				write-teams-log "Failed to delete: $path. Error: $_"
			}
		} else {
			write-teams-log "The provided path does not exist: $path"
		}
	}
}

# Function to remove machine wide installer 
Function Remove-TeamsMachineWideInstaller {
	$processorArchitecture = $env:PROCESSOR_ARCHITECTURE

	# Determine and output architecture
	if ($processorArchitecture -eq 'AMD64') {
		$msiProductCode = "{731F6BAA-A986-45A4-8936-7C3AAAAA760B}"
		Start-Process "msiexec.exe" -ArgumentList "/x $msiProductCode /qn ALLUSERS=1" -Wait
		write-teams-log "Uninstalled machine wide 64-bit installer"
	} elseif ($processorArchitecture -eq 'x86') {
		$msiProductCode = "{39AF0813-FA7B-4860-ADBE-93B9B214B914}"
		Start-Process "msiexec.exe" -ArgumentList "/x $msiProductCode /qn ALLUSERS=1" -Wait
		write-teams-log "Uninstalled machine wide x86 installer"
	}
	
	# if msiexec.exe is not uninstalling Teams wide installer from machine
	# Here performing following additional actions to remove Teams wide installer
	# 1. Removing the regkey "TeamsMachineInstaller/TeamsMachineUninstallerLocalAppData/TeamsMachineUninstallerProgramData" from Run key
	# 2. Deleting the Teams Installer folder
    Remove-TeamsWideInstallerRunKey -valueName 'TeamsMachineInstaller'
    Remove-TeamsWideInstallerRunKey -valueName 'TeamsMachineUninstallerLocalAppData'
    Remove-TeamsWideInstallerRunKey -valueName 'TeamsMachineUninstallerProgramData'

	
	# Uninstall Teams Machine-Wide Installer
	$msiExecPath = "${Env:ProgramFiles(x86)}\Teams Installer\"
	# Delete the Teams Installer folder if it exists
	if (Test-Path $msiExecPath) {
		Remove-Item -Path $msiExecPath -Recurse -Force
	}
	
	Remove-TeamsWideInstallerUninstallKey
}

Function Create-PostScriptExecutionRegkeyEntry {
	$registryPath = "registry::HKLM\Software\Microsoft\TeamsAdminLevelScript"
	$null = New-Item -Path $registryPath -Force -ErrorAction SilentlyContinue
}

write-teams-log "Looking for application(s): $($applicationDefinitions.Name -join ', ')"
$foundList = Find-WindowsApplication -ApplicationDefinitions $applicationDefinitions -AllUsers
if ($foundList) {
	$ScriptResult.NumApplicationsFound = $foundList.Count
	write-teams-log "Found $(@($foundList).Count.ToString('#,###')) application(s)"
	#"Removing apps..."
	$removeList = Remove-WindowsApplication -Applications @($foundList)
	if ($removeList -ne $null) {
		$ScriptResult.NumApplicationsRemoved = $removeList.Count
		write-teams-log "Removed applications: $(@($removeList | Where-Object { $_.Successful -eq $true }).AppDefinition.Name -join ', ')"
	} else {
		write-teams-log "Warning: No application(s) were removed."
	}
} else {
    write-teams-log "Warning: Didn't find any applications."
}

# Function to remove only stale regkey entries from the HKEY_USERS
Remove-TeamsStaleRegKeys

# Function to remove the stale user name entries whose entry is not present in HKLM/:{$username)
Remove-TeamsStaleUserProfileFileSystemEntries

# Function to remove TMA entries
Remove-TeamsMeetingAddin

# Function to remove machine wide installer 
Remove-TeamsMachineWideInstaller

#Function to remove PatchCache files for old teams versions
Remove-PatchCacheFiles

# Function to remove machine wide backup msi installer
Remove-TeamsMachineWideBackupMsiInstaller

if ($SkipAllArtifactsRemoval -eq $false) {
	Remove-vdiCleanup
}

Create-PostScriptExecutionRegkeyEntry

# Deleting the shortcuts
$TeamsIcon_old = "$($ENV:SystemDrive)\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams*.lnk"
Get-Item $TeamsIcon_old | Remove-Item -Force -Recurse

$ScriptResult | ConvertTo-Json -Compress
# SIG # Begin signature block
# MIIoLQYJKoZIhvcNAQcCoIIoHjCCKBoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCaw5YwsDH84HDg
# Don5Qz9yONldgDTCD7cuPbjvKMmSDqCCDXYwggX0MIID3KADAgECAhMzAAAEBGx0
# Bv9XKydyAAAAAAQEMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjQwOTEyMjAxMTE0WhcNMjUwOTExMjAxMTE0WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC0KDfaY50MDqsEGdlIzDHBd6CqIMRQWW9Af1LHDDTuFjfDsvna0nEuDSYJmNyz
# NB10jpbg0lhvkT1AzfX2TLITSXwS8D+mBzGCWMM/wTpciWBV/pbjSazbzoKvRrNo
# DV/u9omOM2Eawyo5JJJdNkM2d8qzkQ0bRuRd4HarmGunSouyb9NY7egWN5E5lUc3
# a2AROzAdHdYpObpCOdeAY2P5XqtJkk79aROpzw16wCjdSn8qMzCBzR7rvH2WVkvF
# HLIxZQET1yhPb6lRmpgBQNnzidHV2Ocxjc8wNiIDzgbDkmlx54QPfw7RwQi8p1fy
# 4byhBrTjv568x8NGv3gwb0RbAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU8huhNbETDU+ZWllL4DNMPCijEU4w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMjkyMzAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAIjmD9IpQVvfB1QehvpC
# Ge7QeTQkKQ7j3bmDMjwSqFL4ri6ae9IFTdpywn5smmtSIyKYDn3/nHtaEn0X1NBj
# L5oP0BjAy1sqxD+uy35B+V8wv5GrxhMDJP8l2QjLtH/UglSTIhLqyt8bUAqVfyfp
# h4COMRvwwjTvChtCnUXXACuCXYHWalOoc0OU2oGN+mPJIJJxaNQc1sjBsMbGIWv3
# cmgSHkCEmrMv7yaidpePt6V+yPMik+eXw3IfZ5eNOiNgL1rZzgSJfTnvUqiaEQ0X
# dG1HbkDv9fv6CTq6m4Ty3IzLiwGSXYxRIXTxT4TYs5VxHy2uFjFXWVSL0J2ARTYL
# E4Oyl1wXDF1PX4bxg1yDMfKPHcE1Ijic5lx1KdK1SkaEJdto4hd++05J9Bf9TAmi
# u6EK6C9Oe5vRadroJCK26uCUI4zIjL/qG7mswW+qT0CW0gnR9JHkXCWNbo8ccMk1
# sJatmRoSAifbgzaYbUz8+lv+IXy5GFuAmLnNbGjacB3IMGpa+lbFgih57/fIhamq
# 5VhxgaEmn/UjWyr+cPiAFWuTVIpfsOjbEAww75wURNM1Imp9NJKye1O24EspEHmb
# DmqCUcq7NqkOKIG4PVm3hDDED/WQpzJDkvu4FrIbvyTGVU01vKsg4UfcdiZ0fQ+/
# V0hf8yrtq9CkB8iIuk5bBxuPMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGg0wghoJAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAQEbHQG/1crJ3IAAAAABAQwDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDv659qEG/aW0kW+73tCFcpy
# f1Lei5IGDKp2BAeQF1ajMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAWyniO19d3c+2igCtgCCLG2bHPwfqAi14p1z3mi63FBZSvk/KXUUiB9o+
# Br48eJMipZmXb40FkgjbyX3OP/CePhlkHw6RmtiJP4D0zjIxyO4L4jy56s/tjMYc
# 1CU8fMCPeOMaKSVZI6zpgSokTqoQ6dXJx1cEZThrsWZ2OY7+0WLJ8J06e6U+zz/X
# 0hh5sj9Opx2kDEGHVCPS0+U8Rvkswd/ZFboc1zsHWMSjcB65GUAd/54Klt8SaZXJ
# mDWZF+ZUloSfj2h+56RtLh3YMwh1Gv5xdrfhkRFXfT8wlJyhSXlwr37KLLF/gUSE
# ukFjuftd3KV3B7Pg3sVdfc07o6TvvqGCF5cwgheTBgorBgEEAYI3AwMBMYIXgzCC
# F38GCSqGSIb3DQEHAqCCF3AwghdsAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCA4qnUppgM80XHBN+J3Alkmds4SzBLQXY8t1a679XKpmwIGZ7ekGhFv
# GBMyMDI1MDMwNTIyMzEyOC4xMjZaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OTIwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHtMIIHIDCCBQigAwIBAgITMwAAAgkIB+D5XIzmVQABAAACCTANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yNTAxMzAxOTQy
# NTVaFw0yNjA0MjIxOTQyNTVaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OTIwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDClEow9y4M3f1S9z1xtNEETwWL1vEiiw0oD7SXEdv4
# sdP0xsVyidv6I2rmEl8PYs9LcZjzsWOHI7dQkRL28GP3CXcvY0Zq6nWsHY2QamCZ
# FLF2IlRH6BHx2RkN7ZRDKms7BOo4IGBRlCMkUv9N9/twOzAkpWNsM3b/BQxcwhVg
# sQqtQ8NEPUuiR+GV5rdQHUT4pjihZTkJwraliz0ZbYpUTH5Oki3d3Bpx9qiPriB6
# hhNfGPjl0PIp23D579rpW6ZmPqPT8j12KX7ySZwNuxs3PYvF/w13GsRXkzIbIyLK
# EPzj9lzmmrF2wjvvUrx9AZw7GLSXk28Dn1XSf62hbkFuUGwPFLp3EbRqIVmBZ42w
# cz5mSIICy3Qs/hwhEYhUndnABgNpD5avALOV7sUfJrHDZXX6f9ggbjIA6j2nhSAS
# Iql8F5LsKBw0RPtDuy3j2CPxtTmZozbLK8TMtxDiMCgxTpfg5iYUvyhV4aqaDLwR
# BsoBRhO/+hwybKnYwXxKeeOrsOwQLnaOE5BmFJYWBOFz3d88LBK9QRBgdEH5CLVh
# 7wkgMIeh96cH5+H0xEvmg6t7uztlXX2SV7xdUYPxA3vjjV3EkV7abSHD5HHQZTrd
# 3FqsD/VOYACUVBPrxF+kUrZGXxYInZTprYMYEq6UIG1DT4pCVP9DcaCLGIOYEJ1g
# 0wIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFEmL6NHEXTjlvfAvQM21dzMWk8rSMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBcXnxvODwk4h/jbUBsnFlFtrSuBBZb7wSZ
# fa5lKRMTNfNlmaAC4bd7Wo0I5hMxsEJUyupHwh4kD5qkRZczIc0jIABQQ1xDUBa+
# WTxrp/UAqC17ijFCePZKYVjNrHf/Bmjz7FaOI41kxueRhwLNIcQ2gmBqDR5W4TS2
# htRJYyZAs7jfJmbDtTcUOMhEl1OWlx/FnvcQbot5VPzaUwiT6Nie8l6PZjoQsuxi
# asuSAmxKIQdsHnJ5QokqwdyqXi1FZDtETVvbXfDsofzTta4en2qf48hzEZwUvbkz
# 5smt890nVAK7kz2crrzN3hpnfFuftp/rXLWTvxPQcfWXiEuIUd2Gg7eR8QtyKtJD
# U8+PDwECkzoaJjbGCKqx9ESgFJzzrXNwhhX6Rc8g2EU/+63mmqWeCF/kJOFg2eJw
# 7au/abESgq3EazyD1VlL+HaX+MBHGzQmHtvOm3Ql4wVTN3Wq8X8bCR68qiF5rFas
# m4RxF6zajZeSHC/qS5336/4aMDqsV6O86RlPPCYGJOPtf2MbKO7XJJeL/UQN0c3u
# ix5RMTo66dbATxPUFEG5Ph4PHzGjUbEO7D35LuEBiiG8YrlMROkGl3fBQl9bWbgw
# 9CIUQbwq5cTaExlfEpMdSoydJolUTQD5ELKGz1TJahTidd20wlwi5Bk36XImzsH4
# Ys15iXRfAjCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
# hvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# MjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAy
# MDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25Phdg
# M/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPF
# dvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6
# GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBp
# Dco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF50Zu
# yjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpGdc3E
# XzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0
# lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1q
# GFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ
# +QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSFF5PA
# PBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkw
# EgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxG
# NSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARV
# MFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAK
# BggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
# AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvX
# zpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20v
# cGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYI
# KwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG
# 9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0x
# M7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmC
# VgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449
# xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wM
# nosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDS
# PeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2d
# Y3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxn
# GSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+Crvs
# QWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAoGokL
# jzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggNQ
# MIICOAIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjkyMDAtMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQB8
# 762rPTQd7InDCQdb1kgFKQkCRKCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA63NFTjAiGA8yMDI1MDMwNTIxNDkw
# MloYDzIwMjUwMzA2MjE0OTAyWjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDrc0VO
# AgEAMAoCAQACAgXmAgH/MAcCAQACAhNqMAoCBQDrdJbOAgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBACI/4+7l9WqVEX46DVLJSNVuYNxRCs3wtpRlIK9OggNw
# 0EeP+ILnS9fdHBKxKDZCdfyfbz0Iv8oLPJ+1azYI7zWQqcJ5JfmHcVhWif511uV+
# S73KExEYfnSku9odLun2cRx+JChXWGIAh6RCfTmF8El1AISs5bMvHWz1yp0JB2cr
# vtLy9/tr9OSk132Gn6c0onqCl4mkvM52fofcjfGd3W3YY9Yxo1fn0c9nTMB91XOU
# rypHPJcPF/asuHgiUdtctVthfMwhj3IdAcfPOVwb+sY69Prb6mZ/EwhMzyT2dBXs
# Na0od9M1Yhk6UuEN7AeKyllCU7OJrmXV6Yii5kXhNaMxggQNMIIECQIBATCBkzB8
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1N
# aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAgkIB+D5XIzmVQABAAAC
# CTANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEE
# MC8GCSqGSIb3DQEJBDEiBCBl2xhOMclUZECdEL45NTXWRLDNlsrEJw3NDxLEP3Hi
# CTCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIGgbLB7IvfQCLmUOUZhjdUqK
# 8bikfB6ZVVdoTjNwhRM+MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTACEzMAAAIJCAfg+VyM5lUAAQAAAgkwIgQg+rZ94dvSMG+ML4t/1nM/5X9c
# 2hx/UAba2AX6Bx5kX8wwDQYJKoZIhvcNAQELBQAEggIAGahEs8t7V1JVCzamlSre
# jsr8O4P23sd49R+j+r191bpx1LArmPkjVInLVXgA4xzW6f9BCHy7wdojzg44qixa
# vctxpRKaangyg2Z26Et9zkzDrcGjSBEbQQTykW4qvWh7r7THYruMPvWyFQQh82zA
# F1xaxPWiu01oq2ltIdgJLowJoT5bZdKAz2ihIlu1rHZlmlAEFmrFP092x0Nfmq7u
# PuyeyJEfPpmha4MQV24IGz3IGUhdxmAT+y9lu394WOX0ThBS4F0UySrjY92Rzs92
# 4jab3pL/r2YLvy/k4ROm8uKJy2uj7LbT657jd1qittI/pIRWK939IIB+/adrdq8b
# 8SJyDh4sryZZ1KzIqpqd4+kspLhJ79cU/s1tZhaDZq/yVuzIOe+aCNbGyXH8bYmr
# VdqFvYspU2YDZ69VjOd4+Tvws4pV1s4T6wUfGk+XH1VqcPH+j5yewzvXb44VE0Zx
# me71uU+y1ECREwmHWx0IX/QikzV2G1V/YvG5ThKGhCI6I+5SGtzuJ0dbPHi6xQ4F
# 0JDwgKi1BwdnZe+YIn3cDXiiZ/z6emIAFSvOmaOzkoVjDs7KkLaCsUmYGfeAUEtO
# /fO5EAL++gr5ssuXkETvwpgVyHyuSoMOChplk8QAq6ivQeAGor8+zGtaXA7/EGx1
# 62G1AagqxA3pmZiLooZcuo4=
# SIG # End signature block
