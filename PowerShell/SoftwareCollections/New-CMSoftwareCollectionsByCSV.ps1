
# Site configuration
$SiteCode = "CNT" # Site code 
$ProviderMachineName = "memcm.contoso.com" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

# Grab applications names
$applications = Import-Csv "C:\Temp\Software.csv"

# Set the limiting collection
$LimitingCollection = "All Workstations"

# Set the import path (Device Collections Folder)
$ImportPath = 'Software'

ForEach ($app in $applications) {
    # Generate a new daily CM Schedule
    [string]$h = Get-Random -Minimum '1' -Maximum '23'
    $h = $h.PadLeft(2,'0')
    [string]$m = Get-Random -Minimum '1' -Maximum '59'
    $m = $m.PadLeft(2,'0')
    $startTime = Get-Date -Format o -Hour $h -Minute $m

    $colSchedule = New-CMSchedule -DurationInterval Days -DurationCount 0 -RecurInterval Days -RecurCount 1 -Start $startTime

    # Set the naming variables
    $disName = $app.DisplayName
    $ProductName = $app.ProductName

    # Set the app name
    $Name = "Software | " + $app.Publisher + " - " + $disName

    # Determine if the Collection already exists
    If (Get-CMDeviceCollection -Name $Name) {
        Write-Host "$Name collection already exists." -ForegroundColor Yellow
    }
    Else {
        # Determine the operator
        If ($app.Operator -eq "equal") {
            $op = "= `"$ProductName`""
        }
        ElseIf ($app.Operator -eq "LikeEndsWith") {
            $op = "like `"%$ProductName`""
        }
        ElseIf ($app.Operator -eq "LikeBeginsWith") {
            $op = "like `"$ProductName%`""
        }
        ElseIf ($app.Operator -eq "LikeContains") {
            $op = "like `"%$ProductName%`""
        }
        Else {
            Write-Host "No operator value for $disName" -ForegroundColor Red
            return
        }

        # Set the query
        $wql = "select SMS_R_SYSTEM.ResourceID,
            SMS_R_SYSTEM.ResourceType,
            SMS_R_SYSTEM.Name,
            SMS_R_SYSTEM.SMSUniqueIdentifier,
            SMS_R_SYSTEM.ResourceDomainORWorkgroup,
            SMS_R_SYSTEM.Client
        from SMS_R_System
            inner join SMS_G_System_INSTALLED_SOFTWARE on SMS_G_System_INSTALLED_SOFTWARE.ResourceID = SMS_R_System.ResourceId
        where SMS_G_System_INSTALLED_SOFTWARE.ProductName $op"

        # Create a Collection with a daily sync, based on the generated name
        Write-Host "Creating collection: $name"
        New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $name -Comment "Software collection for devices with $disName installed." -RefreshType Periodic -RefreshSchedule $colSchedule | Add-CMDeviceCollectionQueryMembershipRule -QueryExpression $wql -RuleName $name

        # Get the built collection, as the move step cannot be piped without breaking other pipes
        $builtCol = Get-CMDeviceCollection -Name $name

        # Move the collection
        Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\$ImportPath" -InputObject $builtCol

        # Clear op
        Clear-Variable -Name "op"
    }
}