# Define the root path of the ConfigMgr inboxes
$inboxRoot = "D:\Program Files\Microsoft Configuration Manager\inboxes"

# Validate the path exists
If (-not (Test-Path $inboxRoot)) {
    Write-Error "Inbox root path not found: $inboxRoot"
    return
}

# Get all subfolders recursively under the inbox root
$folders = Get-ChildItem -Path $inboxRoot -Directory -Recurse

# Collect file counts per folder
$results = ForEach ($folder in $folders) {
    $fileCount = (Get-ChildItem -Path $folder.FullName -File -ErrorAction SilentlyContinue).Count
    [PSCustomObject]@{
        Folder     = $folder.FullName
        FileCount  = $fileCount
    }
}

# Sort by file count descending and display
$results | Sort-Object -Property FileCount -Descending | Format-Table -AutoSize
