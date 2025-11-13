# Run Nessus bug report and collect logs

# Set reusable variables
$date = Get-Date -Format 'yyyyMMdd'
$logPath = 'C:\ProgramData\Tenable\Nessus Agent\nessus\logs'
$tempFolder = "$env:WINDIR\Temp\Tenable"
$nessusWinLogFolder = "$env:windir\Logs\Tenable"
$archiveName = "$env:COMPUTERNAME-$date-NessusOfflineDebug.zip"
$server = ''

# Create the folders if they do not exist
If (!(Test-Path $tempFolder)) {
    New-Item -Path $tempFolder -ItemType Directory | Out-Null
} Else {
    Get-ChildItem -Path "$tempFolder\" | Remove-Item -Force
}
If (!(Test-Path $nessusWinLogFolder)) {
    New-Item -Path $nessusWinLogFolder -ItemType Directory | Out-Null
} Else {
    Get-ChildItem -Path "$nessusWinLogFolder" | Remove-Item -Force
}

# Test if the NessusCLI.exe exists
If (Test-Path "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe") {
    # It does, run the bug report generator
    & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" bug-report-generator --quiet --scrub --full

    # Sleep for 20 seconds to make sure its finished
    Start-Sleep -Seconds 20

    # Copy the files from the log folder to the Temp folder; this is because the files are in use and Compress-Archive cannot handle that, but Copy-Item can
    Copy-Item -Path "$logPath\*" -Destination $tempFolder -Force

    # Compress the files and save the zip to the log folder
    Get-ChildItem $tempFolder | Compress-Archive -DestinationPath "$nessusWinLogFolder\$archiveName"

    # Test if the device can ping the destination server
    If (Test-NetConnection -ComputerName $server -Hops 1 -InformationLevel Quiet) {
        Copy-Item -Path "$nessusWinLogFolder\$archiveName" -Destination "\\$server\Source\Logs\TenableDebug" -Force
        Write-Output 'Log file generated and copied to the server.'
        exit 0
    } Else {
        Write-Output 'Unable to reach the server to copy the zip file.'
        exit 1
    }
} Else {
    Write-Output 'NessusCLI.exe not found. Aborting'
    exit 1
}