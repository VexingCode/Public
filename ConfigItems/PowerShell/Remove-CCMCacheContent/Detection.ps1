# Detection

Function Get-CCMCacheContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $CacheItemsToDelete,
        [Parameter(Mandatory=$true)]
        [ValidateSet('ConfigMgr','Intune','Discovery')]
        [string]
        $Output
    )

    # Connect to resource manager COM object    
    $CMObject = New-Object -ComObject 'UIResource.UIResourceMgr' 
    
    # Using GetCacheInfo method to return cache properties 
    $CMCacheObjects = $CMObject.GetCacheInfo()

    # Loop through the $CacheItemsToDelete
    ForEach ($item in $CacheItemsToDelete) {
        If ($CMCacheObjects.GetCacheElements() | Where-Object { $_.ContentID -in $item }) {
            If ($Output -eq 'Discovery') {
                Write-Host "$item found in cache:" -ForegroundColor Red
                Write-Host $(($CMCacheObjects.GetCacheElements() | Where-Object { $_.ContentID -in $item } | Out-String)).Trim() -ForegroundColor Yellow
            } ElseIf ($Output -eq 'Intune') {
                exit 1
            } ElseIf ($Output -eq 'ConfigMgr') {
                return $false
            }
        } Else {
            If ($Output -eq 'Discovery') {
                Write-Host "$item not found in cache." -ForegroundColor Green
            }
        }
    }

    If ($Output -eq 'Intune') {
        exit 0
    } ElseIf ($Output -eq 'ConfigMgr') {
        return $true
    }
}

Get-CCMCacheContent -CacheItemsToDelete "Content_GUID" -Output ConfigMgr