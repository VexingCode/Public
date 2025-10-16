Function Get-InboxFileCounts {
    [CmdletBinding()]
    param (
        [string]$InboxRoot = "D:\Program Files\Microsoft Configuration Manager\inboxes",
        [switch]$HideZeroCount
    )

    # Validate the path exists
    If (-not (Test-Path $InboxRoot)) {
        Write-Error "Inbox root path not found: $InboxRoot"
        return
    }

    # Get all subfolders recursively under the inbox root
    $folders = Get-ChildItem -Path $InboxRoot -Directory -Recurse

    # Collect file counts per folder
    $results = ForEach ($folder in $folders) {
        $fileCount = (Get-ChildItem -Path $folder.FullName -File -ErrorAction SilentlyContinue).Count
        [PSCustomObject]@{
            Folder    = $folder.FullName
            FileCount = $fileCount
        }
    }

    # Optionally filter out folders with zero files
    If ($HideZeroCount) {
        $results = $results | Where-Object { $_.FileCount -gt 0 }
    }

    # Sort and display
    $results | Sort-Object -Property FileCount -Descending | Format-Table -AutoSize
}