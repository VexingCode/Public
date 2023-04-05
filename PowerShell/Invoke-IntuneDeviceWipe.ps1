<#
.SYNOPSIS
    Auth against Azure, fetch a device by name, and wipe it.
.DESCRIPTION
    This will fetch and auth token for the specified username, to be used with Graph API, utilizing the Microsoft 
    Get-AuthToken function. It will then use Graph to search for a device by the specified name, and pull the
    Device ID. Once it has the ID, it will once again use Graph to POST a wipe command.
.EXAMPLE
    PS C:\> Invoke-IntuneDeviceWipe -Username 'IntuneAdmin@contoso.com' -DeviceName 'AZR-SERIAL'

    This will grab an $authToken for 'IntuneAdmin@contoso.com', then run a wipe on the device named 'AZR-SERIAL'.
.INPUTS
    -Username
        This parameter specifies the account to fetch the $authToken for. Please ensure it has the correct Intune
        permissions assigned/checked out.
    -DeviceName
        This parameter specifies the name of the device you would like to wipe.
    -DeviceType (DEV)
        ***CURRENTLY IN DEV, JUST A PLACE HOLDER***
        This parameter specifies the type of device that you are targeting.
        Valid Values:
                Windows
                Android
                iOS
.NOTES
    Name:           Invoke-IntuneDeviceWipe.ps1
    Author:         Ahnamataeus Vex
    Credit:         Dave Falkus
                        Utilized the Get-AuthToken function from:
                            https://github.com/microsoftgraph/powershell-intune-samples/blob/master/CompliancePolicy/CompliancePolicy_Get.ps1
    Version:        1.0.0
    Release Date:   2022-12-24
    Notes:
                    BE CAREFUL. THIS WILL INITIATE A WIPE ON THE DEVICE. DO NOT PASS GO. DO NOT COLLECT $200.
                    Ensure that you have the Intune admin role assigned/checked out, first.
    To-Do:
                    - Add parameter for the device ID, if you already have it (use parameter set vs device name)
                    - Logging (because duh)
                    - Error handling
                    - Expand to all device types (+ Android, iOS)
#>

get
Function Invoke-IntuneDeviceWipe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Username,
        <#[Parameter(Mandatory=$true)]
        [ValidateSet('Windows','Android','iOS')]
        [string]
        $DeviceType,#>
        [Parameter(Mandatory=$true)]
        [string]
        $DeviceName
    )

    # Embedding Dave Falkus' script to get an Auth Token
    Function Get-AuthToken {

        <#
        .SYNOPSIS
        This function is used to authenticate with the Graph API REST interface
        .DESCRIPTION
        The function authenticate with the Graph API Interface with the tenant name
        .EXAMPLE
        Get-AuthToken
        Authenticates you with the Graph API interface
        .NOTES
        NAME: Get-AuthToken
        #>
        
        [cmdletbinding()]
        
        param
        (
            [Parameter(Mandatory=$true)]
            $User
        )
        
        $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
        
        $tenant = $userUpn.Host
        
        Write-Host "Checking for AzureAD module..."
        
            $AadModule = Get-Module -Name "AzureAD" -ListAvailable
        
            if ($null -eq $AadModule) {
        
                Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
                $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
        
            }
        
            if ($null -eq $AadModule) {
                write-host
                write-host "AzureAD Powershell module not installed..." -f Red
                write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
                write-host "Script can't continue..." -f Red
                write-host
                exit
            }
        
        # Getting path to ActiveDirectory Assemblies
        # If the module count is greater than 1 find the latest version
        
            if($AadModule.count -gt 1){
        
                $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
        
                $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
        
                    # Checking if there are multiple versions of the same module found
        
                    if($AadModule.count -gt 1){
        
                    $aadModule = $AadModule | Select-Object -Unique
        
                    }
        
                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
        
            }
        
            else {
        
                $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
        
            }
        
        [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
        
        [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
        
        $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
        
        $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
        
        $resourceAppIdURI = "https://graph.microsoft.com"
        
        $authority = "https://login.microsoftonline.com/$Tenant"
        
            try {
        
            $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
        
            # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
            # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
        
            $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
        
            $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
        
            $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result
        
                # If the accesstoken is valid then create the authentication header
        
                if($authResult.AccessToken){
        
                # Creating header for Authorization token
        
                $authHeader = @{
                    'Content-Type'='application/json'
                    'Authorization'="Bearer " + $authResult.AccessToken
                    'ExpiresOn'=$authResult.ExpiresOn
                    }
        
                return $authHeader
        
                }
        
                else {
        
                Write-Host
                Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
                Write-Host
                break
        
                }
        
            }
        
            catch {
        
            write-host $_.Exception.Message -f Red
            write-host $_.Exception.ItemName -f Red
            write-host
            break
        
            }
        
    }

    # Authenticate the $Username with Azure and get the $authToken via the Get-AuthToken function
    $authToken = Get-AuthToken -User $Username

    # Set the $deviceURI which will be used to get the Device ID
    $deviceURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/`?`$filter=deviceName eq '$graphDeviceName'"

    # Invoke REST to GET the Device ID via Graph
    $graphDeviceID = (Invoke-RestMethod -Method GET -Uri $deviceURI -Headers $authToken).Value.Id

    # Set the $wipeURI with the Device ID
    $wipeURI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$graphDeviceID/wipe"

    # Invoke REST to POST the wipe URI for the Device ID
    Invoke-RestMethod -Method POST -Uri $wipeUri -Headers $authToken
}