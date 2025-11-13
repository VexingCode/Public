# Detection

[int]$GraceDaysFromRelease = 14

# Create log folder if it doesn't exist
$logFolder = "C:\Windows\Logs\M365UpdateCheck"
If (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Cleanup old logs (older than 30 days)
Get-ChildItem -Path $logFolder -Filter "M365UpdateCheck-*.log" | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-30)
} | Remove-Item -Force

# Create timestamp and log file path
$timestamp = (Get-Date).ToString("yyyyMMddHHmm")
$logPath = Join-Path $logFolder "M365UpdateCheck-Detection-$timestamp.log"

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

    Add-Content $logPath "Office version: $officeVersion"
    Add-Content $logPath "Update channel: $channelName"
    Add-Content $logPath "CDN URL: $cdnUrl"
} Else {
    Add-Content $logPath "Office configuration registry key not found. Office may not be installed."
    $exitCode = 0
}

Try {
    $cdnHost = ([System.Uri]$cdnUrl).Host
    Add-Content $logPath "CDN Host: $cdnHost"
} Catch {
    Add-Content $logPath "Failed to parse CDN URL."
    Add-Content $logPath "Log complete: $timestamp"
    exit
}

$cdnTest = Test-NetConnection -ComputerName $cdnHost -Port 443 -WarningAction SilentlyContinue
If ($cdnTest.TcpTestSucceeded) {
    Add-Content $logPath "CDN connectivity test passed (port 443 reachable)."
} Else {
    Add-Content $logPath "CDN connectivity test failed. Device may be unable to reach update source."
}

$localBuild = $officeVersion -replace "^16\.0\.", ""

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
            Add-Content $logPath "Latest build for $channelName`: $latestBuild (Version $versionNumber)"
        }

        If ($versionNumber) {
            $dateLine = $lines | Where-Object { $_ -match "Version\s+$versionNumber`:\s+\w+\s+\d{1,2}" } | Select-Object -First 1
            If ($dateLine -match "Version\s+$versionNumber`:\s+(\w+\s+\d{1,2})") {
                $releaseDate = [datetime]::ParseExact($matches[1], "MMMM d", $null)
                Add-Content $logPath "Release date of latest build: $releaseDate"
            }
        }
    } Catch {
        Add-Content $logPath "Failed to retrieve latest build info for $channelName."
    }
} Else {
    Add-Content $logPath "No update URL defined for channel: $channelName"
}

If ($latestBuild) {
    $localMajorMinor = ($localBuild -split "\.")[0..1] -join "."
    $latestMajorMinor = ($latestBuild -split "\.")[0..1] -join "."

    Add-Content $logPath "Detected local Major.Minor version: $localMajorMinor"
    Add-Content $logPath "Detected latest Major.Minor version for $channelName`: $latestMajorMinor"

    If ([version]$localMajorMinor -lt [version]$latestMajorMinor) {
        $now = Get-Date
        If ($releaseDate) {
            $daysSinceRelease = ($now - $releaseDate).Days
            $graceThreshold = $releaseDate.AddDays($GraceDaysFromRelease)

            Add-Content $logPath "Current date: $now"
            Add-Content $logPath "Days since release: $daysSinceRelease"
            Add-Content $logPath "Grace threshold date: $graceThreshold"

            If ($now -lt $graceThreshold) {
                Add-Content $logPath "Local build is outdated but within grace period. Update not triggered."
                $exitCode = 0
            } Else {
                Add-Content $logPath "Local build is behind latest. Update task should be triggered."
                $exitCode = 1
            }
        }
    } Else {
        Add-Content $logPath "Local build is up to date or newer. No update task needed."
        $exitCode = 0
    }
}

Add-Content $logPath "Exit code: $exitCode"
Add-Content $logPath "Log complete: $timestamp"
exit $exitCode