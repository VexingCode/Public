<#
.SYNOPSIS
    Function to assign licensing for 365 and Azure.
.DESCRIPTION
    This function will allow you to set licensing, on a user's Cloud record, for licenses listed below.

    Licenses available:
        Microsoft 365
        Audio Conferencing
        Visio
        Project
        Azure P(x)
        Power Automate
        Intune
        Windows 365 VM
        Phone System (DISABLED DUE TO LICENSE DEPENDENCIES)
.EXAMPLE
    PS C:\> Set-LicenseAttribute -Users JDoe -License 'ME5S' -Visio 'VIS2' -Project 'PRJ3' -AudioConferencing
    This example sets the Licensing code for Microsoft 365 E3, with Visio Plan 2, Project Plan 3, and 
    AudioConferencing added.

    PS C:\> Set-LicenseAttribute -Users JDoe -License 'MF3S' -Project 'PRJ3' -AudioConferencing
    This example sets the Licensing code for Microsoft 365 F3, with Project Plan 3, and Audio Conferencing.

    PS C:\> Set-LicenseAttribute -Users JDoe -License 'MF3S' -PowerAutomate 'PAPU'
    This example sets the Licensing code for Microsoft 365 F3 and PowerAutomate Per User.

    PS C:\> Set-LicenseAttribute -Users JDoe -License 'ME3S' -Visio 'None' -PowerAutomate 'PAPU'
    This example sets the Licensing code for Microsoft 365 F3 and PowerAutomate Per User, and removes the license
    for Visio.

    PS C:\> Set-LicenseAttribute -Users JDoe -License 'Clear'
    This example will clear ALL licensing from BOTH OnPrem and Cloud attributes.
.INPUTS
    -User
        This parameter specifies the user you would like to apply the license to. Does not currently support
        multiple users. This is a REQUIRED field.
    -Domain
        This parameter specifies the domain you you are targeting. It will be used to assemble the UPN. Format
        is "domain.com".
    -License 
        This parameter will assign the Microsoft 365 license to the user by writing one of the listed values to the
        extension_(AZURE-APP-GUID)_Lic365 field. This is a REQUIRED field, even if you only want to change one of 
        the other licenses.
        Valid options are:
            Clear = Clear all of the licensing fields, no matter if others are specified
            None =  This will set the license to 'None'; use this to remove a license or for accounts that do not
                    need a license (good for service accounts)
            MF1S = Microsoft 365 F1
            MF3S = Microsoft 365 F3
            ME3S = Microsoft 365 E3
            ME5S = Microsoft 365 E5
    -Visio
        This parameter will assign a Visio license to the user by writing one of the listed values to the 
        extension_(AZURE-APP-GUID)_LicVisio field. Please note that this license can be 
        assigned no matter the licensing level above.
            VIS2 = Visio Plan 2
            None = Clear the license
    -Project
        This parameter will assign a Project license to the user by writing one of the listed values to the 
        extension_(AZURE-APP-GUID)_LicProject field. Please note that this license can be assigned no matter 
        the licensing level above.
            PRJ3 = Project Plan 3
            None = Clear the license
    -AudioConferencing
        This parameter will assign the Audio Conferencing line to a user, as long as they have a valid base
        license, by changing the last value from "S" to "A". Those licenses are:
            MF3S
            ME3S
            ME5S
    -AzurePx
        This parameter will assign an AzureP(x) license to the user by writing one of the listed values to the 
        extension_(AZURE-APP-GUID)_LicAzurePx field. Please note that this license can be assigned no matter 
        the licensing level above.
            AZP2 = Azure Plan 2
            None = Clear the license
    -PowerAutomate
        This parameter will assign a PowerAutomate license to the user by writing one of the listed values to the 
        extension_(AZURE-APP-GUID)_LicPwrAutomate field. Please note that this license can be assigned no matter 
        the licensing level above.
            PAPU = Power Automate Per User
            PAPUAR = Power Automate Per user with Attended RPA
            None = Clear the license
    -Intune
        This parameter will assign the Intune license to the user by writing the value "INTN" to the 
        extension_(AZURE-APP-GUID)_LicIntune field. Please note that this license can be assigned no matter the 
        licensing level above. Currently, this only is intended for Cloud accounts and should only really be used 
        for service accounts and the like.
            INTN = Intune License
            None = Clear the license
    -Win365
        This parameter will assign a Windows 365 VM license to the user by writing one of the listed values to the 
        extension_(AZURE-APP-GUID)_LicWin365 field. Please note that the user still needs to be assigned a Win365 
        image as well (probably another parameter to come; haven't decided).
            2C8R128S = 2 core, 8gb RAM, 128gb Storage
            4C16R128S = 4 core, 16gb RAM, 128gb Storage
            None = Clear the license
    -PhoneSystem (CURRENTLY DISABLED DUE TO DEPENDENCY LICENSING)
        This parameter will assign a Phone System license to the user by writing one of the listed values to the 
        extension_(AZURE-APP-GUID)_LicPhoneSystem field.
            MTPS = Microsoft Teams Phone System
            None = Clear the license
    -Verbose
        Self explanatory.    
.OUTPUTS
    Before and after licenses.
    Verbose comments, if specified with -Verbose.
.NOTES
    Name:      Set-LicenseAttribute.ps1
    Author:    Ahnamataeus Vex
    Version: 1.0.0
    Release Date: 2020-09-22
        Updated:
            Version 1.0.1: 2020-11-04
                Added the ME3A code as an acceptable value.
                Also updated the examples as the -User parameter was missing.
            Version 1.0.2: 2020.12.11
                Added the 'Clear' code as an acceptable value for License; this will clear all of the licensing fields including Visio and Project
            Version 2.0.0: 2021.09.13
                    Expanded the 'Clear' value to also clear all of the new Cloud attributes
                    Added the -AzurePx parameter to assign an Azure P2 license
                    Added the -PowerAutomate parameter to assign a PowerAutomate Per User license
                Removed the old "Office 365" values
                Added the 'None' code as an acceptable value for License; this will set the license to nothing since nothing queries on that
            Version 2.0.1: 2021.10.07
                Added the -Intune parameter to assign an Intune license
            Version 3.0.0; big overhaul: 
                Converted the following parameters from switches to strings, with validated sets. This allows us to either leave
                the parameter value alone (E.g., don't clear it), or set it individually to 'None' to remove the license
                    -Visio
                        Newly specified values:
                            VIS2
                            None
                    -Project
                        Newly specified values:
                            PRJ3
                            None
                    -PwrAutomate (Renamed to -PowerAutomate)
                        Newly specified values:
                            PAPU
                            PAPUAR
                            None
                    -AzurePx
                        Newly specified values:
                            AZP2
                            None
                    -Intune
                        Newly specified values:
                            INTN
                            None
                Added the following parameters, and their values:
                    -Win365
                        Values:
                            2C8R128S
                            4C16R128S
                            None
                    -PhoneSystem
                        Values:
                            MTPS
                            None
    To Do:
        Create parameter for assigning PowerBI licenses
            Set ValidateSet
        Add a check for elevated console, if not then install the AzureAD module to the current user
#>

Function Set-LicenseAttribute {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [string] $User,
        [parameter(Mandatory = $true)]
        [string] $Domain,
        [parameter(Mandatory = $true)]
        [ValidateSet('Clear', 'None', 'MF1S', 'MF3S', 'MF3A', 'ME3S', 'ME3A', 'ME5S')]
        [string] $License,
        [parameter(Mandatory = $false)]
        [ValidateSet('VIS2','None')]
        [string] $Visio,
        [parameter(Mandatory = $false)]
        [ValidateSet('PRJ3','None')]
        [string] $Project,
        [parameter(Mandatory = $false)]
        [switch] $AudioConferencing,
        [parameter(Mandatory = $false)]
        [ValidateSet('AZP2','None')]
        [string] $AzurePx,
        [parameter(Mandatory = $false)]
        [ValidateSet('PAPU', 'PAPUAR','None')]
        [string] $PowerAutomate,
        [parameter(Mandatory = $false)]
        [ValidateSet('INTN','None')]
        [string] $Intune,
        [parameter(Mandatory = $false)]
        [ValidateSet('2C8R128S','4C16R128S','None')]
        [string] $Win365,
        <#[parameter(Mandatory = $false)]
        [ValidateSet('MTPS','None')]
        [string] $PhoneSystem,#>
        [parameter(Mandatory = $false)]
        [switch] $Cloud
    )

    # Check for elevation; set AzureAD module install to CurrentUser if not
    # Modify the below command to this purpose
    <# If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
        Break
    } #>

    Function Install-AzureADModule {
        Write-Verbose 'Grabbing the version of AzureAD from the gallery...'
        $GalleryModuleVersion = (Find-Module AzureAD).Version
        Write-Verbose 'Gallery version is:'
        Write-Verbose $GalleryModuleVersion
        Write-Verbose 'Grabbing the version of AzureAD that is installed (if any)...'
        $InstalledModuleVersion = (Get-InstalledModule AzureAD -ErrorAction SilentlyContinue).Version
        Write-Verbose 'Installed version is:'
        Write-Verbose $InstalledModuleVersion
        Write-Verbose 'Comparing the two to see if the gallery is newer...'
        If (!($InstalledModuleVersion -ge $GalleryModuleVersion)) {
            Write-Verbose 'Gallery version is newer, or its not installed.'
            Write-Verbose 'Installing the AzureAD module.'
            Install-Module AzureAD -Force -AllowClobber
            Write-Verbose 'Importing the AzureAD module...'
            Import-Module AzureAD
            Write-Verbose 'Connecting to AzureAD. Please ensure you are using a privileged account.'
            Connect-AzureAD
        }
        Else {
            Write-Verbose 'AzureAD module is current.'
            Try {
                $aadConnectionCheck = Get-AzureADTenantDetail
                $tenant = $aadConnectionCheck.DisplayName
                Write-Verbose "AzureAD already connected to: $tenant"
                Write-Verbose "Skipping connection step."
            } 
            Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
                Write-Host "Not currently connected to AzureAD."
                Write-Verbose 'Connecting to AzureAD. Please ensure you are using a privileged account.'
                Connect-AzureAD
            }
        }
    }

    Function Get-PostLicValues {
        Write-Verbose 'License attribute values set.'
        # Gather the new license properties for the user
        Write-Verbose 'Gathering the new license attributes from the user...'
        $newLic365 = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLic365
        $newLicVisio = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicVisio
        $newLicProject = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicProject
        $newLicAzurePx = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicAzurePx
        $newLicPwrAutomate = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicPwrAutomate
        $newLicIntune = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicIntune
        $newLicWin365 = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicWin365
        $newLicPhoneSystem = ((Get-AzureADUser -ObjectId $userCloud.ObjectID).extensionproperty).$extLicPhoneSystem

        # Return the Old and New Properties
        Write-Verbose "Returning license attributes, with before and after values."
        $licObject = $null
        $licObject = @()
        $licObject += [PSCustomObject]@{License = "365"; Old = $currentLic365; New = $newLic365}
        $licObject += [PSCustomObject]@{License = "Visio"; Old = $currentLicVisio; New = $newLicVisio}
        $licObject += [PSCustomObject]@{License = "Project"; Old = $currentLicProject; New = $newLicProject}
        $licObject += [PSCustomObject]@{License = "Azure P(x)"; Old = $currentLicAzurePx; New = $newLicAzurePx}
        $licObject += [PSCustomObject]@{License = "Power Automate"; Old = $currentLicPwrAutomate; New = $newLicPwrAutomate}
        $licObject += [PSCustomObject]@{License = "Intune"; Old = $currentLicIntune; New = $newLicIntune}
        $licObject += [PSCustomObject]@{License = "Windows 365"; Old = $currentLicWin365; New = $newLicWin365}
        $licObject += [PSCustomObject]@{License = "Phone System"; Old = $currentLicPhoneSystem; New = $newLicPhoneSystem}
        $licObject
    }

    # Set the variables for the extension attributes
    Write-Verbose 'Setting cloud extension attribute variables.'
    $extLic365 = 'extension_(AZURE-APP-GUID)_Lic365'
    $extLicVisio = 'extension_(AZURE-APP-GUID)_LicVisio'
    $extLicProject = 'extension_(AZURE-APP-GUID)_LicProject'
    $extLicAzurePx = 'extension_(AZURE-APP-GUID)_LicAzurePx'
    $extLicPwrAutomate = 'extension_(AZURE-APP-GUID)_LicPwrAutomate'
    $extLicIntune = 'extension_(AZURE-APP-GUID)_LicIntune'
    $extLicWin365 = 'extension_(AZURE-APP-GUID)_LicWin365'
    $extLicPhoneSystem = 'extension_(AZURE-APP-GUID)_LicPhoneSystem'
    $allExtLic = $extLic365,$extLicVisio,$extLicProject,$extLicAzurePx,$extLicPwrAutomate,$extLicIntune,$extLicWin365,$extLicPhoneSystem
    # Make sure that the AzureAD module is downloaded, imported, and connected
    Write-Verbose 'Beginning AzureAD module verification...'
    Install-AzureADModule
    # Attach domain to username, so Azure accepts it
    $user = $user + "@" + $domain
    Write-Verbose "Converted provided username and domain to UPN: $user"
    If (!(Get-AzureADUser -Filter "userPrincipalName eq '$user'")) {
        Write-Verbose "Error: $user does not exist!"
        Return
    }
    Else {
        Write-Verbose "Success: $user exists. Proceeding..."
        # Gather the user's ObjectId into a variable
        Write-Verbose "Gathering the user's ObjectId..."
        $userCloud = Get-AzureADUser -ObjectId $user
        # Gather the current license attribute values for the user
        Write-Verbose 'Gathering the current license attribute values for the user...'
        $currentLic365 = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLic365
        $currentLicVisio = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicVisio
        $currentLicProject = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicProject
        $currentLicAzurePx = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicAzurePx
        $currentLicPwrAutomate = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicPwrAutomate
        $currentLicIntune = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicIntune
        $currentLicWin365 = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicWin365
        $currentLicPhoneSystem = ((Get-AzureADUser -ObjectId $userCloud.ObjectId).extensionproperty).$extLicPhoneSystem
        # If the License value is Clear; nuke everything
        If ($License -eq 'Clear') {
            Write-Verbose "Clear parameter specified. Clearing all attributes. Any other specifed parameters will be ignored."
            # Loop through each of the license attribute values and set them to 'None'
            ForEach ($lic in $allExtLic) {
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $lic -ExtensionValue 'None'
            }
            # Assemble the license values and display them
            Get-PostLicValues
        }
        Else {
            # Check for the Audio Conferencing Parameter and set the license value if present
            If ($AudioConferencing) {
                Write-Verbose 'AudioConferencing was specified; ensuring correct License values.'
                If ( ($License -eq 'MF3S') -or ($License -eq 'MF3A') ) {
                    $License = 'MF3A'
                    Write-Verbose "Audio Conferencing parameter specified. Ensuring license is set to MF3A."
                }
                ElseIf ( ($License -eq 'ME3S') -or ($License -eq 'ME3A') ) {
                    $License = 'ME3A'
                    Write-Verbose "Audio Conferencing parameter specified. Ensuring license is set to ME3A."
                }
                ElseIf ( ($License -eq 'ME5S') -or ($License -eq 'ME5A') ) {
                    $License = 'ME5A'
                    Write-Verbose "Audio Conferencing parameter specified. Ensuring license is set to ME5A."
                }
                Else {
                    Write-Verbose "No valid base license assigned!"
                    Return
                }
            }
            # Set the 365 license (with or without AudioConferencing)
            If ($License -eq 'None') {
                Write-Verbose "License parameter specified as 'None'; setting $extLic365 to 'None'."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLic365 -ExtensionValue 'None'
            }
            Else {
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLic365 -ExtensionValue $License
                Write-Verbose "License parameter specified; setting $extLic365 to $License."
            }
            # Set the Visio license
            If ($Visio -eq 'VIS2') {
                Write-Verbose "Visio parameter specified as 'Visio Plan 2'; setting $extLicVisio to $Visio."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicVisio -ExtensionValue 'VIS2'
            }
            ElseIf ($Visio -eq 'None') {
                Write-Verbose "Visio parameter specified as 'None'; setting $extLicVisio to $Visio."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicVisio -ExtensionValue 'None'
            }
            Else {
                Write-Verbose "Visio parameter not specified; leaving as is."
            }
            # Set the Project License
            If ($Project -eq 'PRJ3') {
                Write-Verbose "Project parameter specified as 'Project Plan 3'; setting $extLicProject to $Project."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicProject -ExtensionValue 'PRJ3'
            }
            ElseIf ($Project -eq 'None') {
                Write-Verbose "Project parameter specified as 'None'; setting $extLicProject to $Project."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicProject -ExtensionValue 'None'
            }
            Else {
                Write-Verbose "Project parameter not specified; leaving as is."
            }
            # Set the Azure P(x) License
            If ($AzurePx -eq 'AZP2') {
                Write-Verbose "Azure P(x) parameter specified as 'Azure P2'; setting $extLicAzurePx to $AzurePx."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicAzurePx -ExtensionValue 'AZP2'
            }
            ElseIf ($AzurePx -eq 'None') {
                Write-Verbose "Azure P(x) parameter specified as 'None'; setting $extLicAzurePx to $AzurePx."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicAzurePx -ExtensionValue 'None'
            }
            Else {
                Write-Verbose "Azure P(x) parameter not specified; leaving as is."
            }
            # Set the PowerAutomate License
            If ($PowerAutomate -eq 'PAPU') {
                Write-Verbose "PowerAutomate parameter specified as 'Power Automate Per User'; setting $extLicPwrAutomate to $PowerAutomate."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicPwrAutomate -ExtensionValue 'PAPU'
            }
            ElseIf ($PowerAutomate -eq 'PAPUAR') {
                Write-Verbose "PowerAutomate parameter specified as 'Power Automate Per User with Attended RPA'; setting $extLicPwrAutomate to $PowerAutomate."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicPwrAutomate -ExtensionValue 'PAPUAR'
            }
            ElseIf ($PowerAutomate -eq 'None') {
                Write-Verbose "PowerAutomate parameter specified as 'None'; settings $extLicPwrAutomate to $PowerAutomate."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicPwrAutomate -ExtensionValue 'None'
            }
            Else {
                Write-Verbose "PowerAutomate parameter not specified; leaving as is."
            }
            # Set the Intune License
            If ($Intune -eq 'INTN') {
                Write-Verbose "Intune parameter specified as 'Intune'; settings $extLicIntune to $Intune."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicIntune -ExtensionValue 'INTN'
            }
            ElseIf ($Intune -eq 'None') {
                Write-Verbose "Intune parameter specified as 'None'; setting $extLicIntune to $Intune."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicIntune -ExtensionValue 'None'
            }
            Else {
                Write-Verbose "Intune parameter not specified; leaving as is."
            }
            # Set the Win365 License
            If ($Win365 -eq '4C16R128S') {
                Write-Verbose "Windows 365 VM parameter specified as '4 cores, 16gb RAM, 128gb Storage'; settings $extLicWin365 to $Win365."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicWin365 -ExtensionValue '4C16R128S'
            }
            If ($Win365 -eq '2C8R128S') {
                Write-Verbose "Windows 365 VM parameter specified as '2 cores, 8gb RAM, 128gb Storage'; settings $extLicWin365 to $Win365."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicWin365 -ExtensionValue '2C8R128S'
            }
            ElseIf ($Win365 -eq 'None') {
                Write-Verbose "Windows 365 VM parameter specified as 'None'; setting $extLicWin365 to $Win365."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extLicWin365 -ExtensionValue 'None'
            }
            Else {
                Write-Verbose "Windows 365 VM parameter not specified; leaving as is."
            }
            <# Set the Phone System License; NOTE: THIS LICENSE HAS A DEPENDENCY, LIKELY ON A 365. DISABLING FOR NOW.
            If ($PhoneSystem -eq 'MTPS') {
                Write-Verbose "Phone System parameter specified as 'Microsoft Teams Phone Standard'; settings $extLicPhoneSystem to $PhoneSystem."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extPhoneSystem -ExtensionValue 'MTPS'
            }
            ElseIf ($PhoneSystem -eq 'None') {
                Write-Verbose "Phone System parameter specified as 'None'; setting $extLicPhoneSystem to $PhoneSystem."
                Set-AzureADUserExtension -ObjectId $userCloud.ObjectId -ExtensionName $extPhoneSystem -ExtensionValue 'None'
            }
            Else {
                Write-Verbose "Phone System parameter not specified; leaving as is."
            }#>
            # Assemble the License values and display them
            Get-PostLicValues
        }
    }
}