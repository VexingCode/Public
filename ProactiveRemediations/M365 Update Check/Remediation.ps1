# Remediation

Function Invoke-M365UpdateCheck {
    [CmdletBinding()]
    param (
        [switch]$Detection,
        [int]$GraceDaysFromRelease = 14
    )

    # Define log folder and file
    $logFolder = "C:\Windows\Logs\M365UpdateCheck"
    If (-not (Test-Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }

    # Clean up old logs (older than 30 days)
    Get-ChildItem -Path $logFolder -Filter "M365UpdateCheck*.log" | Where-Object {
        $_.LastWriteTime -lt (Get-Date).AddDays(-30)
    } | Remove-Item -Force

    # Create timestamped log file
    $timestamp = Get-Date -Format "yyyyMMddHHmm"
    $logFile = Join-Path $logFolder "M365UpdateCheck-Remediation-$timestamp.log"

    # Logging function
    Function Write-Log {
        param ([string]$Message)
        $Message | Out-File -FilePath $logFile -Append -Encoding UTF8
    }

    # Set some location variables
    $officeC2RClient = "$Env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
    $versionRegPath = "HKLM:\Software\Microsoft\Office\ClickToRun\Configuration"

    # Gather version and channel info
    If (Test-Path $versionRegPath) {
        $props = Get-ItemProperty -Path $versionRegPath
        $officeVersion = $props.ClientVersionToReport
        $cdnUrl = $props.UpdateChannel

        $channelMap = @{
            "492350f6-3a01-4f97-b9c0-c7c6ddf67d60" = "Current Channel"
            "55336b82-a18d-4dd6-b5f6-9e5095c314a6" = "Monthly Enterprise Channel"
            "7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" = "Semi-Annual Enterprise Channel"
            "b8f9b850-328d-4355-9145-c59439a0c4cf" = "Semi-Annual Enterprise Channel (Preview)"
            "5440fd1f-7ecb-4221-8110-145efaa6372f" = "Beta Channel"
            "64256afe-f5d9-4f86-8936-8840a6a4f5be" = "Current Channel (Preview)"
        }

        $channelGuid = If ($cdnUrl) { $cdnUrl -replace ".*/", "" } Else { "Unknown" }
        $channelName = $channelMap[$channelGuid]
        If (-not $channelName) { $channelName = "Unknown Channel ($channelGuid)" }

        Write-Log "Office version: $officeVersion"
        Write-Log "Update channel: $channelName"
        Write-Log "CDN URL: $cdnUrl"
    } Else {
        Write-Log "Office configuration registry key not found. Office may not be installed."
        return
    }

    # Extract hostname from CDN URL
    Try {
        $cdnHost = ([System.Uri]$cdnUrl).Host
        Write-Log "CDN Host: $cdnHost"
    } Catch {
        Write-Log "Failed to parse CDN URL."
        return
    }

    # Test connectivity to CDN host
    $cdnTest = Test-NetConnection -ComputerName $cdnHost -Port 443 -WarningAction SilentlyContinue
    If ($cdnTest.TcpTestSucceeded) {
        Write-Log "CDN connectivity test passed (port 443 reachable)."
    } Else {
        Write-Log "CDN connectivity test failed. Device may be unable to reach update source."
    }

    # Strip "16.0." prefix from local version
    $localBuild = $officeVersion -replace "^16\.0\.", ""

    # Define URLs for latest build info per channel
    $channelUrls = @{
        "Current Channel" = "https://learn.microsoft.com/en-us/officeupdates/current-channel"
        "Monthly Enterprise Channel" = "https://learn.microsoft.com/en-us/officeupdates/monthly-enterprise-channel"
        "Semi-Annual Enterprise Channel" = "https://learn.microsoft.com/en-us/officeupdates/semi-annual-enterprise-channel"
        "Semi-Annual Enterprise Channel (Preview)" = "https://learn.microsoft.com/en-us/officeupdates/semi-annual-enterprise-channel-preview"
    }

    $latestBuild = $null
    $releaseDate = $null
    $versionNumber = $null

    If ($channelUrls.ContainsKey($channelName)) {
        Try {
            $html = Invoke-WebRequest -Uri $channelUrls[$channelName] -UseBasicParsing
            $lines = $html.Content -split "`n"

            $buildLine = $lines | Where-Object { $_ -match "Version\s+(\d+)\s+\(Build\s+(\d+\.\d+)\)" } | Select-Object -First 1
            If ($buildLine -match "Version\s+(\d+)\s+\(Build\s+(\d+\.\d+)\)") {
                $versionNumber = $matches[1]
                $latestBuild = $matches[2]
                Write-Log "Latest build for $channelName`: $latestBuild (Version $versionNumber)"
            }

            If ($versionNumber) {
                $dateLine = $lines | Where-Object { $_ -match "Version\s+$versionNumber`:\s+\w+\s+\d{1,2}" } | Select-Object -First 1
                If ($dateLine -match "Version\s+$versionNumber`:\s+(\w+\s+\d{1,2})") {
                    $releaseDate = [datetime]::ParseExact($matches[1], "MMMM d", $null)
                    Write-Log "Release date of latest build: $releaseDate"
                }
            }
        } Catch {
            Write-Log "Failed to retrieve latest build info for $channelName."
        }
    } Else {
        Write-Log "No update URL defined for channel: $channelName"
    }

    If ($latestBuild) {
        $localMajorMinor = ($localBuild -split "\.")[0..1] -join "."
        $latestMajorMinor = ($latestBuild -split "\.")[0..1] -join "."

        Write-Log "Detected local Major.Minor version: $localMajorMinor"
        Write-Log "Detected latest Major.Minor version for $channelName`: $latestMajorMinor"

        If ([version]$localMajorMinor -lt [version]$latestMajorMinor) {
            $now = Get-Date
            If ($releaseDate) {
                $daysSinceRelease = ($now - $releaseDate).Days
                $graceThreshold = $releaseDate.AddDays($GraceDaysFromRelease)

                Write-Log "Current date: $now"
                Write-Log "Days since release: $daysSinceRelease"
                Write-Log "Grace threshold date: $graceThreshold"

                If ($now -lt $graceThreshold) {
                    Write-Log "Local build is outdated but within grace period. Update not triggered."
                    return
                }
            }

            Write-Log "Local build is behind latest. Update task should be triggered."

            If (-not $Detection) {
                Write-Log "Triggering update..."
                If (Test-Path $officeC2RClient) {
                    Start-Process -FilePath $officeC2RClient -ArgumentList "/update USER displaylevel=false" -Wait
                    Write-Log "Update trigger completed."
                } Else {
                    Write-Log "OfficeC2RClient.exe not found. Unable to initiate update."
                }
            } Else {
                Write-Log "Detection mode enabled. Update not triggered."
            }
        } Else {
            Write-Log "Local build is up to date or newer. No update task needed."
        }
    }
}

Invoke-M365UpdateCheck
