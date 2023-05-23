Function Import-VexingCodeCollections {

    <#
    .SYNOPSIS
        Function used to build collections in ConfigMgr, by grabbing WQL queries from my GitHub.
    .DESCRIPTION
        This function will allow anyone to create collections within ConfigMgr, based on the collections
        within my GitHub. The intention is that users can quickly build out collections in a new or test
        environment. Contributions to the function, or the collections in general are greatly appreciated!
    .PARAMETER SiteCode
        A mandatory parameter to specify the sitecode for you ConfigMgr instance.
    .PARAMETER SiteServer
        A mandatory parameter to specify your site server.
    .PARAMETER LimitingCollection
        A parameter to specify the name of the limiting collection. If no parameter is specified, then 
        "All Systems" (SMS00001) will be used.
    .PARAMETER OSCollections
        A switch that specifies you would like to import the OS collections.
    .PARAMETER ClientHealthCollections
        A switch that specifies you would like to import the Client Health Collections.
    .PARAMETER ClientMDEHealthCollections
        A switch that specifies you would like to import the Client MDE Health collections.
    .PARAMETER DogfoodCollections
        A switch that specifies you would like to import the Dogfood collections.
    .PARAMETER CMRolesCollections
        A switch that specifies you would like to import the ConfigMgr Role collections.
    .PARAMETER HardwareCollections
        A switch that specifies you would like to import the Hardware collections.
    .PARAMETER ImportPath
        The path that you want the devices to be dropped into. The structure for this command is: "Folder\Folder"
    .EXAMPLE
        Import-VexingCodeCollections -SiteCode 'CNT' -SiteServer 'MEMCMYo' -OSCollections
        
        This will create the OS Collections in your ConfigMgr instance. They will have the default limiting collection
        of "All Systems" and be placed at the default Device Collections root folder.
    .EXAMPLE
        Import-VexingCodeCollections -SiteCode 'CNT' -SiteServer 'MEMCMYo' -LimitingCollection "All Devices and Servers" -OSCollections -ImportPath 'Testing\Import'

        This will import the OS Collections into your ConfigMgr instance. They will have the limited collection of
        "All Workstation and Servers" then be moved to the 'CNT:\DeviceCollection\Testing\Import' folder.
    .NOTES
            Name:      Import-VexingCodeCollections.ps1
            Author:    Ahnamataeus Vex
            Version: 1.0.0
            Release Date: 2022-05-06
            To Do:
                - Something something logging...
                - Expand to the rest of the collection types
                - Either clean the file names in my Git (probably a better option...), or script out more
                to support the additional collection types
                - Add all requested collections to one var, and process it at the end
                - Allow for Limiting Collection ID or Name (filter if it starts with SMS or $SiteCode?)
    #>

    #Requires -Version 5.0
    #Requires -runasadministrator

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $SiteCode,
        [Parameter(Mandatory = $true)]
        [string]
        $SiteServer,
        [Parameter()]
        [string]
        $LimitingCollection,
        [Parameter()]
        [switch]
        $OSCollections,
        [Parameter()]
        [switch]
        $ClientHealthCollections,
        [Parameter()]
        [switch]
        $ClientMDEHealthCollections,
        [Parameter()]
        [switch]
        $DogfoodCollections,
        [Parameter()]
        [switch]
        $DogfoodExtCollections,
        [Parameter()]
        [switch]
        $CMRolesCollections,
        [Parameter()]
        [switch]
        $HardwareCollections,
        [Parameter()]
        [switch]
        $FirmwareCollections,
        [Parameter()]
        [switch]
        $SoftwareCollections,
        [Parameter()]
        [string]
        $ImportPath
    )

    # Set the CM module initialization parameters
    $initParams = @{}
    #$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
    $initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

    # Load the CM module
    Try {
        # Detect if the module is imported
        If ((Get-Module ConfigurationManager) -eq $null) {
            # Import it
            Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
        }
        # Check if the drive exists
        If ($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            # Create the drive
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer @initParams
        }
    }
    Catch {
        Throw "Failed to import CM module."
    }

    # Set the user and repo
    $user = 'VexingCode'
    $repo = 'Public'

    # Set the limiting collection to "All Systems" if $null
    # Not working, figure out why
    If ($null -eq $LimitingCollection) {
        $LimitingCollection = "All Systems"
    }

    # Set regex for later use
    $regex = [Regex]::new("(?<=Query_).*?(?=_)")

    # Generate a new daily CM Schedule
    Function New-RandomCMSchedule {
        $minute = Get-Random -Minimum 0 -Maximum 59
        $hour = Get-Random -Minimum 0 -Maximum 23
        New-CMSchedule -Start (Get-Date -Hour $hour -Minute $minute) -DurationInterval Days -DurationCount 0 -RecurInterval Days -RecurCount 1
    }

    # If OS Collections are requested
    If ($OSCollections) {
        # Set the path to the OS Collection files
        $path = 'WQL/OSVer'

        # Get all of the files in that path
        $repoFiles = Invoke-RestMethod "https://api.github.com/repos/$user/$repo/contents/$path"

        # Loop through the files found in the repo
        ForEach ($file in $repoFiles) {
            # Pull the download_Url, which is the raw content URL
            $wql = Invoke-RestMethod $file.download_Url

            # Generate a name based off of the preconfigured file name
            $name = (($file).Name).Replace("Query_","OS | ").Replace(".wql","").Replace("_"," ")

            # Generate the new CM Schedule
            $colSchedule = New-RandomCMSchedule

            # Create a Collection with a daily sync, based on the generated name
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment $name -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

            # Detect if ImportPath is specified and if so, move it to the requested folder; if there is a typo it will not be moved
            # NOTE: If nothing is specified it will be created in "Device Collections" at the top
            If ($null -ne $ImportPath) {
                # Get the built collection, as the move step cannot be piped without breaking other pipes
                $builtCol = Get-CMDeviceCollection -Name $name
                # Move the collection
                Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol
            }
        }
    }

    # If ClientHealth Collections are requested
    If ($ClientHealthCollections) {
        # Set the path to the ClientHealth Collection files
        $path = 'WQL/ClientHealth'

        # Get all of the files in that path
        $repoFiles = Invoke-RestMethod "https://api.github.com/repos/$user/$repo/contents/$path"

        # Loop through the files found in the repo
        ForEach ($file in $repoFiles) {
            # Pull the download_Url, which is the raw content URL
            $wql = Invoke-RestMethod $file.download_Url

            # Generate a name based off of the preconfigured file name
            $name = (($file).Name).Replace("Query_","Health | ").Replace(".wql","").Replace("_"," ").Replace("-"," - ")

            # Generate the new CM Schedule
            $colSchedule = New-RandomCMSchedule

            # Create a Collection with a daily sync, based on the generated name
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment $name -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

            # Detect if ImportPath is specified and if so, move it to the requested folder; if there is a typo it will not be moved
            # NOTE: If nothing is specified it will be created in "Device Collections" at the top
            If ($null -ne $ImportPath) {
                # Get the built collection, as the move step cannot be piped without breaking other pipes
                $builtCol = Get-CMDeviceCollection -Name $name
                # Move the collection
                Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol
            }
        }
    }

    # If ClientMDEHealth Collections are requested
    If ($ClientMDEHealthCollections) {
        # Set the path to the ClientMDEHealth Collection files
        $path = 'WQL/ClientMDEHealth'

        # Get all of the files in that path
        $repoFiles = Invoke-RestMethod "https://api.github.com/repos/$user/$repo/contents/$path"

        # Loop through the files found in the repo
        ForEach ($file in $repoFiles) {
            # Pull the download_Url, which is the raw content URL
            $wql = Invoke-RestMethod $file.download_Url

            # Generate a name based off of the preconfigured file name
            $name = (($file).Name).Replace("Query_","MDE Health | ").Replace(".wql","").Replace("_"," ").Replace("-"," - ")

            # Generate the new CM Schedule
            $colSchedule = New-RandomCMSchedule

            # Create a Collection with a daily sync, based on the generated name
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment $name -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

            # Detect if ImportPath is specified and if so, move it to the requested folder; if there is a typo it will not be moved
            # NOTE: If nothing is specified it will be created in "Device Collections" at the top
            If ($null -ne $ImportPath) {
                # Get the built collection, as the move step cannot be piped without breaking other pipes
                $builtCol = Get-CMDeviceCollection -Name $name
                # Move the collection
                Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol
            }
        }
    }

    # If Dogfood Collections are requested
    If ($DogfoodCollections) {
        # Set the path to the Dogfood Collection files
        $path = 'WQL/Dogfood'

        # Get all of the files in that path
        $repoFiles = Invoke-RestMethod "https://api.github.com/repos/$user/$repo/contents/$path"

        # Loop through the files found in the repo
        ForEach ($file in $repoFiles) {
            # Pull the download_Url, which is the raw content URL
            $wql = Invoke-RestMethod $file.download_Url

            # Generate a name based off of the preconfigured file name
            $name = (($file).Name).Replace("Query_","Dogfood | ").Replace(".wql","").Replace("_"," ")

            # Generate the new CM Schedule
            $colSchedule = New-RandomCMSchedule

            # Create a Collection with a daily sync, based on the generated name
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment $name -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

            # Detect if ImportPath is specified and if so, move it to the requested folder; if there is a typo it will not be moved
            # NOTE: If nothing is specified it will be created in "Device Collections" at the top
            If ($null -ne $ImportPath) {
                # Get the built collection, as the move step cannot be piped without breaking other pipes
                $builtCol = Get-CMDeviceCollection -Name $name
                # Move the collection
                Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol
            }
        }
    }

    # If Dogfood Collections are requested
    If ($DogfoodExtCollections) {
        # Set the path to the Dogfood Collection files
        $path = 'WQL/DogfoodExtended'

        # Get all of the files in that path
        $repoFiles = Invoke-RestMethod "https://api.github.com/repos/$user/$repo/contents/$path"

        # Loop through the files found in the repo
        ForEach ($file in $repoFiles) {
            # Pull the download_Url, which is the raw content URL
            $wql = Invoke-RestMethod $file.download_Url

            # Generate a name based off of the preconfigured file name
            $name = (($file).Name).Replace("Query_","Dogfood Ext | ").Replace(".wql","").Replace("_"," ")

            # Generate the new CM Schedule
            $colSchedule = New-RandomCMSchedule

            # Create a Collection with a daily sync, based on the generated name
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment $name -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

            # Detect if ImportPath is specified and if so, move it to the requested folder; if there is a typo it will not be moved
            # NOTE: If nothing is specified it will be created in "Device Collections" at the top
            If ($null -ne $ImportPath) {
                # Get the built collection, as the move step cannot be piped without breaking other pipes
                $builtCol = Get-CMDeviceCollection -Name $name
                # Move the collection
                Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol
            }
        }
    }

    # If CMRoles Collections are requested
    If ($CMRolesCollections) {
        # Set the path to the CMRoles Collection files
        $path = 'WQL/CMRoles'

        # Get all of the files in that path
        $repoFiles = Invoke-RestMethod "https://api.github.com/repos/$user/$repo/contents/$path"

        # Loop through the files found in the repo
        ForEach ($file in $repoFiles) {
            # Pull the download_Url, which is the raw content URL
            $wql = Invoke-RestMethod $file.download_Url

            # Generate a name based off of the preconfigured file name
            $name = (($file).Name).Replace("Query_ServersWithCMRoles_","CMRoles | ").Replace(".wql","").Replace("_"," ")

            # Generate the new CM Schedule
            $colSchedule = New-RandomCMSchedule

            # Create a Collection with a daily sync, based on the generated name
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment $name -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

            # Detect if ImportPath is specified and if so, move it to the requested folder; if there is a typo it will not be moved
            # NOTE: If nothing is specified it will be created in "Device Collections" at the top
            If ($null -ne $ImportPath) {
                # Get the built collection, as the move step cannot be piped without breaking other pipes
                $builtCol = Get-CMDeviceCollection -Name $name
                # Move the collection
                Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol
            }
        }
    }

    # If Hardware Collections are requested
    If ($HardwareCollections) {
        # Set the path to the Hardware Collection files
        $path = 'WQL/Hardware'

        # Get all of the files in that path
        $repoFiles = Invoke-RestMethod "https://api.github.com/repos/$user/$repo/contents/$path"

        # Loop through the files found in the repo
        ForEach ($file in $repoFiles) {
            # Pull the download_Url, which is the raw content URL
            $wql = Invoke-RestMethod $file.download_Url

            # Generate a name based off of the preconfigured file name
            $fileName = ($file).Name
            $prefix = $regex.Match($fileName).Value
            $name = ($fileName).Replace("Query_","Hardware | ").Replace(".wql","").Replace("_"," ").Replace("$prefix ","$prefix - ")

            # Generate the new CM Schedule
            $colSchedule = New-RandomCMSchedule

            # Create a Collection with a daily sync, based on the generated name
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment $name -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

            # Detect if ImportPath is specified and if so, move it to the requested folder; if there is a typo it will not be moved
            # NOTE: If nothing is specified it will be created in "Device Collections" at the top
            If ($null -ne $ImportPath) {
                # Get the built collection, as the move step cannot be piped without breaking other pipes
                $builtCol = Get-CMDeviceCollection -Name $name
                # Move the collection
                Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol
            }
        }
    }

    # If Firmware Collections are requested
    If ($FirmwareCollections) {
        # Set the path to the Firmware Collection files
        $path = 'WQL/Firmware'

        # Get all of the files in that path
        $repoFiles = Invoke-RestMethod "https://api.github.com/repos/$user/$repo/contents/$path"

        # Loop through the files found in the repo
        ForEach ($file in $repoFiles) {
            # Pull the download_Url, which is the raw content URL
            $wql = Invoke-RestMethod $file.download_Url

            # Generate a name based off of the preconfigured file name
            $name = (($file).Name).Replace("Query_Firmware_","Firmware | ").Replace(".wql","").Replace("_"," ")

            # Generate the new CM Schedule
            $colSchedule = New-RandomCMSchedule

            # Create a Collection with a daily sync, based on the generated name
            New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment $name -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

            # Detect if ImportPath is specified and if so, move it to the requested folder; if there is a typo it will not be moved
            # NOTE: If nothing is specified it will be created in "Device Collections" at the top
            If ($null -ne $ImportPath) {
                # Get the built collection, as the move step cannot be piped without breaking other pipes
                $builtCol = Get-CMDeviceCollection -Name $name
                # Move the collection
                Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol
            }
        }
    }
}