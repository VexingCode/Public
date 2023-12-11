Function Set-WindowsUpdateDriversToApproved {
    param (
            [Parameter(Mandatory=$true)]
            [string]$windowsDriverUpdateProfileId
    )

    #Requires -Modules Microsoft.Graph.Beta.DeviceManagement.Actions

    # Connect MgGraph
    Connect-MgGraph -Scopes DeviceManagementConfiguration.ReadWrite.All

    # URL for Other Drivers:
    $uri = "https://graph.microsoft.com/beta/deviceManagement/windowsDriverUpdateProfiles/$windowsDriverUpdateProfileId/driverInventories?`$filter=category%20eq%20%27other%27"

    # Build the array
    $allPendingDrivers = @()

    # Send the GET request; loop through returned pages
    $pendingDrivers = Invoke-MgGraphRequest -Uri $uri -ContentType 'application/json'
    $allPendingDrivers += $pendingDrivers.Value

    If ($pendingDrivers.'@odata.nextLink') {
        Do {
            $pendingDrivers = Invoke-MgGraphRequest -Uri $pendingDrivers.'@odata.NextLink' -ContentType 'application/json'
            $allPendingDrivers += $pendingDrivers.value
        } Until (
            !$pendingDrivers.'@odata.nextLink'
        )
    }

    # Filter the results and grab the id
    $driverIdsToApprove = $allPendingDrivers | Where-Object {$_.approvalStatus -eq 'needsReview'} | ForEach-Object {$_.id}

    # Loop through the drivers and approve them
    ForEach ($driverId in $driverIdsToApprove) {
        $date = Get-Date
        $params = @{
            actionName = "Approve"
            driverIds = @(
                $driverId
            )
            deploymentDate = $date
        }

        Invoke-MgBetaExecuteDeviceManagementWindowsDriverUpdateProfileAction -WindowsDriverUpdateProfileId $windowsDriverUpdateProfileId -BodyParameter $params
    }
}