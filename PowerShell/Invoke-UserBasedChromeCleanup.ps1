Function Invoke-UserBasedChromeCleanup {
    <#
    .SYNOPSIS
        Detects and optionally remediates user-level Google Chrome installs.

    .DESCRIPTION
        Runs in detection mode by default. If -Remediate is specified, it attempts
        to remove Chrome artifacts. The -Force parameter is only available in the
        Remediate parameter set, allowing cleanup even if the profile is in use.

    .PARAMETER Remediate
        Switch to perform remediation (delete Chrome artifacts). 
        If omitted, runs in detection mode only.

    .PARAMETER Force
        Switch to force remediation even if profile is in use.
        Only available when -Remediate is specified.
    #>

    [CmdletBinding(DefaultParameterSetName="Detect")]
    param(
        [Parameter(ParameterSetName="Remediate")]
        [switch]$Remediate,

        [Parameter(ParameterSetName="Remediate")]
        [switch]$Force
    )

    Write-Host "Checking for user-level Google Chrome installs..." -ForegroundColor Cyan

    $remediationNeeded = $false
    $remediationFailed = $false

    $profiles = Get-ChildItem "C:\Users" -Directory | Where-Object {
        $_.Name -notin @("All Users", "Default", "Default User", "Public")
    }

    ForEach ($profile in $profiles) {
        $profileName = $profile.Name
        $profilePath = $profile.FullName

        Try {
            # Get SID for the profile
            $sid = (Get-CimInstance Win32_UserAccount | Where-Object { $_.LocalPath -eq $profilePath }).SID
            $profileLoaded = $false
            If ($sid -and (Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.Name -like "*$sid" })) {
                $profileLoaded = $true
            }

            If ($profileLoaded -and -not $Force -and $Remediate) {
                Write-Host "Skipping $($profileName) (profile in use)" -ForegroundColor Yellow
                continue
            }
        } Catch {
            Write-Host "Could not resolve SID for $($profileName), proceeding cautiously..." -ForegroundColor DarkYellow
        }

        # Paths
        $chromePath        = Join-Path $profilePath "AppData\Local\Google\Chrome"
        $chromeUpdaterPath = Join-Path $profilePath "AppData\Local\Google\Update"
        $ntUserDat         = Join-Path $profilePath "NTUSER.DAT"
        $desktopIcon       = Join-Path $profilePath "Desktop\Google Chrome.lnk"
        $startMenuIcon     = Join-Path $profilePath "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"

        # Detection: if any artifacts exist, remediation is needed
        ForEach ($artifact in @($chromePath,$chromeUpdaterPath,$desktopIcon,$startMenuIcon)) {
            If (Test-Path $artifact) { $remediationNeeded = $true }
        }

        If (Test-Path $ntUserDat) {
            Try {
                reg load HKU\TempHive $ntUserDat | Out-Null
                ForEach ($key in @(
                    "HKU\TempHive\Software\Google\Chrome",
                    "HKU\TempHive\Software\Google\Update",
                    "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome",
                    "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Uninstall\Google Update"
                )) {
                    If (reg query $key 2>$null) { $remediationNeeded = $true }
                }
                reg unload HKU\TempHive | Out-Null
            } Catch {
                If ($Remediate -and $Force) { $remediationNeeded = $true }
            }
        }

        # Remediation logic
        If ($Remediate) {
            # Kill Chrome-related processes
            $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessName -in @("chrome","googleupdate","googlecrashhandler")
            }
            ForEach ($p in $procs) {
                Try {
                    Stop-Process -Id $p.Id -Force -ErrorAction Stop
                    Write-Host "Terminated $($p.ProcessName) for $($profileName)" -ForegroundColor DarkRed
                } Catch {
                    Write-Host "Failed to terminate $($p.ProcessName) for $($profileName): $_" -ForegroundColor Red
                    $remediationFailed = $true
                }
            }

            ForEach ($path in @($chromePath,$chromeUpdaterPath)) {
                If (Test-Path $path) {
                    Try {
                        Remove-Item $path -Recurse -Force -ErrorAction Stop
                        Write-Host "Removed $path for $($profileName)" -ForegroundColor Green
                    } Catch {
                        Write-Host "Failed to remove $path for $($profileName): $_" -ForegroundColor Red
                        $remediationFailed = $true
                    }
                }
            }

            If (Test-Path $ntUserDat) {
                Try {
                    reg load HKU\TempHive $ntUserDat | Out-Null
                    ForEach ($key in @(
                        "HKU\TempHive\Software\Google\Chrome",
                        "HKU\TempHive\Software\Google\Update",
                        "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome",
                        "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Uninstall\Google Update"
                    )) {
                        reg delete $key /f | Out-Null
                    }
                    reg unload HKU\TempHive | Out-Null
                    Write-Host "Cleaned registry for $($profileName)" -ForegroundColor Magenta
                } Catch {
                    If ($Force) {
                        Write-Host "Hive locked for $($profileName), but Force specified — continuing." -ForegroundColor DarkYellow
                    } Else {
                        Write-Host "Hive locked for $($profileName). Skipped registry cleanup." -ForegroundColor Yellow
                    }
                }
            }

            ForEach ($shortcut in @($desktopIcon,$startMenuIcon)) {
                If (Test-Path $shortcut) {
                    Try {
                        Remove-Item $shortcut -Force
                        Write-Host "Removed Chrome shortcut for $($profileName)" -ForegroundColor Blue
                    } Catch {
                        Write-Host "Failed to remove shortcut for $($profileName): $_" -ForegroundColor Red
                        $remediationFailed = $true
                    }
                }
            }
        }
    }

    # Common Start Menu cleanup
    $commonStartMenuIcon = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
    If (Test-Path $commonStartMenuIcon) {
        $remediationNeeded = $true
        If ($Remediate) {
            Try {
                Remove-Item $commonStartMenuIcon -Force
                Write-Host "Removed common Start Menu Chrome shortcut" -ForegroundColor Blue
            } Catch {
                Write-Host "Failed to remove common Start Menu Chrome shortcut: $_" -ForegroundColor Red
                $remediationFailed = $true
            }
        }
    }

    Write-Host "Chrome detection/remediation complete." -ForegroundColor Cyan

    # Exit appropriately for Intune
    If ($remediationFailed) {
        exit 1
    } ElseIf ($remediationNeeded) {
        exit 1  # detection or remediation required
    } Else {
        exit 0  # nothing to remediate
    }
}