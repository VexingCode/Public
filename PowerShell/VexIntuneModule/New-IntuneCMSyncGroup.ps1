Function New-IntuneCMSyncGroup {

    <#
    .SYNOPSIS
        Function to (somewhat) standardize the creation of the CMSync groups in Entra.
    .DESCRIPTION
        This function will create the group with a naming prefix and a standardized description.
    .PARAMETER CollectionId
        Enter the collection Id for the syncing collection.
    .PARAMETER CollectionName
        Enter the collection name for the syncing collection. If the $GroupName parameter isn't
        specified, then clean and use the collection name as part of the name.
    .PARAMETER GroupName
        Enter the name you want for the group.
    .PARAMETER DeploymentTarget
        Parameter to specify your deployment target for the group.

        This parameter is a validated set, and the options are:
            Device
            User
    .EXAMPLE
        C:\> New-IntuneCMSyncGroup -CollectionId 'CON00001' -CollectionName 'OU | Workstations - Dpt' -GroupName 'Win-Pol-OU-Workstations-Dpt' -DeploymentTarget Device

        This will create a CMSync group with the following information:

        Group Name: MEM-CMSync-Win-Pol-OU-Workstations-Dpt-D
        Group Description: CMSync group. CM Collection Id: COS00001. CM Collection Name: OU | Workstations - Dpt.
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=1)]
        [string]
        $CollectionId,
        [Parameter(Mandatory,Position=2)]
        [string]
        $CollectionName,
        [Parameter(Position=3)]
        [string]
        $GroupName,
        [Parameter(Mandatory,Position=4)]
        [ValidateSet('Device','User')]
        [string]
        $DeploymentTarget
    )

    # Check for an MgGraph connection
    If (!(Get-MgContext)) {
        Connect-MgGraph -NoWelcome
    }

    # Function to clean strings
    Function Clean-String {
        param ([string]$InputString)
        
        # Trim leading and trailing spaces
        $cleanedString = $InputString.Trim()
        
        # Remove non-alphanumeric characters except hyphens
        $cleanedString = $cleanedString -replace '[^a-zA-Z0-9\s-]', ''
        
        # Remove spaces around hyphens
        $cleanedString = $cleanedString -replace '\s*-\s*', '-'
        
        # Replace multiple hyphens with a single hyphen
        $cleanedString = $cleanedString -replace '-+', '-'
        
        # Replace spaces with hyphens
        $cleanedString = $cleanedString -replace '\s+', '-'
        
        return $cleanedString
    }

    # If $GroupName is not specified, set it to the cleaned $CollectionName
    Write-Host "Group Name: $GroupName" -ForegroundColor Yellow
    Write-Host "Collection Name: $CollectionName" -ForegroundColor Yellow
    If (!($GroupName)) {
        $cleanedName = Clean-String -InputString $CollectionName
        Write-Host "Collection Name: $collectionName" -ForegroundColor Cyan
        Write-Host "Cleaned Name: $cleanedName" -ForegroundColor Cyan
    } Else {
        # If it is specified, clean it also
        $cleanedName = Clean-String -InputString $GroupName
        Write-Host "Group Name: $GroupName" -ForegroundColor Magenta
        Write-Host "Collection Name: $collectionName" -ForegroundColor Magenta
        Write-Host "Cleaned Name: $cleanedName" -ForegroundColor Magenta
    }

    # Set the deployment target
    If ($DeploymentTarget -eq 'Device') {
        $dt = "D"
    } Else {
        $dt = "U"
    }

    # Generate the body of the group creation
    $Body = @{
        DisplayName                     = "MEM-CMSync-$cleanedName-$dt"
        Description                     = "CMSync group. CM Collection Id: $($CollectionId.ToUpper()). CM Collection Name: $CollectionName"
        MailEnabled                     = $false
        MailNickname                    = 'NotSet'
        SecurityEnabled                 = $true
    }

    # Create the group
    New-MgBetaGroup -BodyParameter $Body
}