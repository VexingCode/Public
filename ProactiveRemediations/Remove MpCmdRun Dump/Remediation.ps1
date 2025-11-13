# Remediation

Function Remove-MpCmdRunDumps {
    [CmdletBinding()]
    param(
        [switch]$Delete,
        [int]$Days = 30
    )

    $targetPath = 'C:\Windows\ServiceProfiles\LocalService\AppData\Local\Temp'
    $exitCode = 0

    If (-not (Test-Path $targetPath)) {
        Write-Warning "Target path does not exist: $targetPath"
        exit 0
    }

    Write-Host "Scanning for .dmp files older than $Days days in $targetPath..." -ForegroundColor Cyan

    $cutoff = (Get-Date).AddDays(-$Days)
    $oldDumps = Get-ChildItem -Path $targetPath -Filter '*.dmp' -File -Force | Where-Object {
        $_.LastWriteTime -lt $cutoff
    }

    if ($oldDumps.Count -eq 0) {
        Write-Host "No old .dmp files found." -ForegroundColor Green
    } else {
        Write-Host "Found $($oldDumps.Count) .dmp file(s) older than $Days days." -ForegroundColor Yellow

        if ($Delete) {
            foreach ($file in $oldDumps) {
                Write-Host "Deleting: $($file.FullName)" -ForegroundColor Red
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to delete $($file.FullName): $_"
                }
            }
        } else {
            $exitCode = 1  # Found old files, but -Delete not specified
        }
    }

    Write-Host "Exiting with code $exitCode" -ForegroundColor Green
    exit $exitCode
}

Remove-MpCmdRunDumps -Days 30 -Delete