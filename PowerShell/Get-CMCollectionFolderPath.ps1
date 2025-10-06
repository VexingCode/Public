Function Get-CMCollectionFolderPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $true)]
        [string]$SiteCode
    )

    # Get the collection object
    $collection = Get-CMDeviceCollection | Where-Object { $_.Name -eq $CollectionName }
    If (-not $collection) {
        Write-Warning "Collection '$CollectionName' not found."
        return
    }

    # Get the container node mapping
    $containerItem = Get-WmiObject -Namespace "root\SMS\site_$SiteCode" `
        -Class SMS_ObjectContainerItem `
        -Filter "InstanceKey = '$($collection.CollectionID)' AND ObjectType = 5000"

    If (-not $containerItem) {
        Write-Warning "No folder mapping found for collection '$CollectionName'."
        return
    }

    # Recursively build the folder path
    $path = @()
    $nodeID = $containerItem.ContainerNodeID
    While ($nodeID -ne 0) {
        $node = Get-WmiObject -Namespace "root\SMS\site_$SiteCode" `
            -Class SMS_ObjectContainerNode `
            -Filter "ContainerNodeID = $nodeID"
        If (-not $node) { break }
        $path.Insert(0, $node.Name)
        $nodeID = $node.ParentContainerNodeID
    }

    $folderPath = ($path -join "\")
    Write-Output "Collection '$CollectionName' lives in folder: $folderPath"
}