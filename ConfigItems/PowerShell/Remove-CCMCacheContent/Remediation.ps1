# Remediation

Function Remove-CCMCacheContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $CacheItemsToDelete
    )

    # Connect to resource manager COM object    
    $CMObject = New-Object -ComObject 'UIResource.UIResourceMgr' 
    
    # Using GetCacheInfo method to return cache properties 
    $CMCacheObjects = $CMObject.GetCacheInfo()

    # Loop through the $CacheItemsToDelete
    ForEach ($item in $CacheItemsToDelete) {
        $CMCacheObjects.GetCacheElements() | Where-Object { $_.ContentID -in $item } | ForEach-Object { $CMCacheObjects.DeleteCacheElement($_.CacheElementID) }
    }
}

Remove-CCMCacheContent -CacheItemsToDelete "Content_GUID"