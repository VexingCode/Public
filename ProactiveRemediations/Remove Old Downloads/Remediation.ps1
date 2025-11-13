# Remediation

Function Remove-OldDownloads {
    [CmdletBinding()]
    param(
        [switch]$Delete,
        [int]$Days
    )

    $usersPath = "$env:SystemDrive\Users"
    $exitCode = 0

    ForEach ($userFolder in Get-ChildItem -Path $usersPath -Directory) {
        $downloadsPath = Join-Path -Path $userFolder.FullName -ChildPath "Downloads"

        If (Test-Path $downloadsPath) {
            Write-Host "Getting Folders" -ForegroundColor Yellow
            $oldFolders = Get-ChildItem -Path $downloadsPath -Directory -Recurse -Force | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) }
            Write-Host "Getting Files" -ForegroundColor Yellow
            $oldFiles = Get-ChildItem -Path $downloadsPath -File -Recurse -Force | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) }

            Write-Host "Found $($oldFolders.Count) old folders in $downloadsPath" -ForegroundColor Yellow
            If ($oldFolders.Count -gt 0) {
                If ($Delete) {
                    ForEach ($folder in $oldFolders) {
                        Write-Host "Deleting folder: $($folder.FullName)" -ForegroundColor Red
                        Try {
                            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Continue
                        } Catch {
                            Write-Warning "Failed to delete: $($folder.FullName) - $_"
                        }
                    }
                } Else {
                    $exitCode = 1  # Found old files, but -Delete not specified
                }
            }

            If ($oldFiles.Count -gt 0) {
                Write-Host "Found $($oldFiles.Count) old files in $downloadsPath" -ForegroundColor Yellow
                If ($Delete) {
                    ForEach ($file in $oldFiles) {
                        Write-Host "Deleting file: $($file.FullName)" -ForegroundColor Red
                        Try {
                            Remove-Item -Path $file.FullName -Recurse -Force -ErrorAction Continue
                        } Catch {
                            Write-Warning "Failed to delete: $($file.FullName) - $_"
                        }
                    }
                } Else {
                    $exitCode = 1  # Found old files, but -Delete not specified
                }
            }
        }
    }

    Write-Host "Exiting with code $exitCode" -ForegroundColor Green
    exit $exitCode  # Exit 1 in detection, otherwise 0
}

Remove-OldDownloads -Days 30 -Delete