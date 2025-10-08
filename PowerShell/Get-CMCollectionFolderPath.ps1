Function Get-CMCollectionFolderPath {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [string]$CollectionName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string]$CollectionId,

        [Parameter(Mandatory = $true)]
        [string]$SiteCode
    )

    # Resolve collection object
    switch ($PSCmdlet.ParameterSetName) {
        'ByName' {
            $collection = Get-CMCollection -Name $CollectionName
            If (-not $collection) {
                Write-Warning "Collection '$CollectionName' not found."
                return
            }
        }
        'ById' {
            $collection = Get-CMCollection -Id $CollectionId
            If (-not $collection) {
                Write-Warning "Collection ID '$CollectionId' not found."
                return
            }
        }
    }

    # Determine object type: 5000 = device, 5001 = user
    $objectType = If ($collection.CollectionType -eq 2) { 5000 } else { 5001 }

    # Get the container node mapping
    $containerItem = Get-WmiObject -Namespace "root\SMS\site_$SiteCode" `
        -Class SMS_ObjectContainerItem `
        -Filter "InstanceKey = '$($collection.CollectionID)' AND ObjectType = $objectType"

    If (-not $containerItem) {
        Write-Warning "No folder mapping found for collection '$($collection.Name)'."
        return
    }

    # Recursively build the folder path
    $path = New-Object System.Collections.Generic.List[string]
    $nodeID = $containerItem.ContainerNodeID
    while ($nodeID -ne 0) {
        $node = Get-WmiObject -Namespace "root\SMS\site_$SiteCode" `
            -Class SMS_ObjectContainerNode `
            -Filter "ContainerNodeID = $nodeID"
        If (-not $node) { break }
        $path.Insert(0, $node.Name)
        $nodeID = $node.ParentContainerNodeID
    }

    $folderPath = ($path -join "\")
    Write-Output "Collection '$($collection.Name)' lives in folder: $folderPath"
}