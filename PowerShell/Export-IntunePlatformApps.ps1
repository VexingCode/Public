[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ClientSecret,
    [Parameter()]
    [String]
    $ClientId,
    [Parameter()]
    [String]
    $TenantId,
    [Parameter()]
    [String]
    $PipelineExportPath
)

# Update the required modules
Function Update-ModulesInPath {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $Modules,
        [Parameter()]
        [string]
        $Path
    )
  
    # Check for/update the modules
    ForEach($module in $modules) {
        # Getting version of installed module
        $installedModule = Get-Module -ListAvailable "$path\$module" | Sort-Object Version -Descending | Select-Object -First 1
        $installedVersion = if ($installedModule) { $installedModule.Version.ToString() } else { "0.0.0" }
        
        # Getting latest module version from PS Gallery 
        $psgalleryversion = Find-Module -Name $module | Sort-Object Version -Descending | Select-Object -First 1
        $onlineVersion = $psgalleryversion.Version.ToString()
        
        # Path for the installed version
        $installedPath = Join-Path -Path $path -ChildPath "$module\$installedVersion"
        
        If ([version]$installedVersion -ge [version]$onlineVersion) {
            Write-Host "Module $module is up to date."
        } Else {
            Write-Host "Module $module needs to be updated."

            If (Test-Path -Path $installedPath) {
                Remove-Item -Path $installedPath -Recurse -Force
                Write-Host "Old version $installedVersion of $module removed."
            }

            Write-Host "Saving $module version $onlineVersion."
            Save-Module -Name $module -Path $path
            Write-Host "$module updated to version $onlineVersion."
        }
    }

    # Now import the modules
    ForEach ($module in $modules) {
        Write-Host "Importing module $module."
        Import-Module (Get-ChildItem "$path\$module" -Filter *.psd1 -Recurse -Force) -Force
    }
}

# Check the modules for updates
Update-ModulesInPath -Modules "Microsoft.Graph.Authentication","Microsoft.Graph.Beta.DeviceManagement","Microsoft.Graph.Beta.Identity.DirectoryManagement" -Path '.\Modules'

# Load a function to export Intune detected apps for a specific platform
Function Export-IntunePlatformApps {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Windows','Android','iOS','MacOS','Unknown')]
        [string]$Platform,
        [Parameter(Mandatory=$true)]
        [string]$ExportPath
    )
    
    # Test ExportPath; create if non-existent
    If (!(Test-Path $ExportPath)) {
        New-Item -ItemType Directory -Path $ExportPath
    }
    
    # Set export file name
    If ($Platform -eq 'Windows') {
        $ExportFileName = "IntuneDetectedApps-WindowsAndUnknown.csv"
    } Else {
        $ExportFileName = "IntuneDetectedApps-$Platform.csv"
    }
    $ExportFilePath = Join-Path -Path $ExportPath -ChildPath $ExportFileName
    
    # Set platform name from friendly to Graph value (seems to be case sensitive...gross; also, Android is a special case)
    Switch ($Platform) {
        'Windows' { $PlatformName = 'windows' }
        'macOS' { $PlatformName = 'macOS' }
        'iOS' { $PlatformName = 'ios' }
        'Android' { $PlatformName = 'androidDedicatedAndFullyManaged' }
        'Unknown' { $PlatformName = 'unknown' }
        Default { Write-Host "Platform $Platform not recognized. Skipping." -ForegroundColor Red; Continue }
    }
    
    # Get the apps for the specified platform
    $platformApps = Get-MgBetaDeviceManagementDetectedApp -All | Where-Object {$_.Platform -eq $PlatformName}
    
    # If the platform is Windows, also get the apps for the Unknown platform since they commonly are for Windows, and combine the results
    If ($Platform -eq 'Windows') {
        # Sleep  for 10 seconds to avoid throttling
        Start-Sleep -Seconds 10

        # Get the apps for the Unknown platform
        $unknownApps = Get-MgBetaDeviceManagementDetectedApp -All | Where-Object {$_.Platform -eq 'unknown'}

        # Combine the results
        $platformApps = $platformApps + $unknownApps
    }
    
    # Export the results to a CSV
    $platformApps | Export-Csv -Path $ExportFilePath -NoTypeInformation -Force
    Write-Host "Exported detected apps for $Platform to $ExportFilePath." -ForegroundColor Green    
}

# Disconnect any exist MgGraph session
If (Get-MgContext) {
    Disconnect-MgGraph
}

# Connect to Microsoft Graph
$SecureClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecureClientSecret

Write-Host "Connecting to Microsoft Graph with the DvcEng Entra app." -ForegroundColor Cyan
Connect-MgGraph -NoWelcome -tenantId $TenantId -ClientSecretCredential $ClientSecretCredential

# Export apps for each platform
$Platforms = @('Windows','Android','iOS','MacOS','Unknown')

# Export apps for each platform
ForEach ($Platform in $Platforms) {
    Export-IntunePlatformApps -Platform $Platform -ExportPath $PipelineExportPath
    # I've been getting throttled by the Graph API, so I'm adding a delay between each export
    Start-Sleep -Seconds 10
}
