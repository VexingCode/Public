Function New-IntuneEndpointSecurityGroup {

    #Requires -Modules Microsoft.Graph.Beta.Groups

    <#
    .SYNOPSIS
        Creates a new Intune Endpoint Security group.
    .DESCRIPTION
        This function creates a new Intune Endpoint Security group using the Microsoft Graph API. 
        It supports various entities and settings, and allows for the creation of exclusion groups.
    .PARAMETER Entity
        Specifies the entity for the Endpoint Security group. 
        
        Valid values are: 
            Antivirus
            Disk Encryption
            Firewall
            Endpoint Privilege Management 
            Endpoint Detection and Response
            Application Control for Business 
            Attack Surface Reduction
            Account Protection
            Device Compliance
    .PARAMETER OperatingSystem
        Specifies the operating system for the Endpoint Security group. 
        
        Valid values are: 
            Windows
            MacOS
            Linux
            Android
            iOS
    .PARAMETER AVSetting
        Specifies the Antivirus setting for the Endpoint Security group. 
        
        Valid values are: 
            Defender Update Controls
            Defender Exclusions
            Defender Antivirus Configuration
            Windows Security Experience
    .PARAMETER DESetting
        Specifies the Disk Encryption setting for the Endpoint Security group. 
        
        Valid values are: 
            BitLocker
            FileVault
    .PARAMETER FWSetting
        Specifies the Firewall setting for the Endpoint Security group. 
        
        Valid values are: 
            Windows Firewall Rules
            Windows Firewall Configuration
            Windows Hyper-V Firewall Rules
            MacOS Firewall
    .PARAMETER EPMSetting
        Specifies the Endpoint Privilege Management setting for the Endpoint Security group. 
        
        Valid values are: 
            Elevation Rules Policy
            Elevation Rules Settings
    .PARAMETER EDRSetting
        Specifies the Endpoint Detection and Response setting for the Endpoint Security group. 
        
        Valid value is: 
        Endpoint Detection and Response
    .PARAMETER ACBSetting
        Specifies the Application Control for Business setting for the Endpoint Security group. 
        
        Valid value is: 
            Configuration
    .PARAMETER ASRSetting
        Specifies the Attack Surface Reduction setting for the Endpoint Security group. 
        
        Valid values are: 
            App and Browser Isolation
            Attack Surface Reduction Rules
            Device Control
            Exploit Protection
            Application Control
    .PARAMETER ACTPSetting
        Specifies the Account Protection setting for the Endpoint Security group. 
        
        Valid values are: 
            Account Protection
            Local Admin Password Solution
            Local User Group Membership
    .PARAMETER DCSetting
        Specifies the Device Compliance setting for the Endpoint Security group. 
        
        Valid values are: 
            Personally-owned
            Corporate
    .PARAMETER Purpose
        Specifies the purpose of the Endpoint Security group.
    .PARAMETER DeploymentTarget
        Specifies the deployment target for the Endpoint Security group. 
        
        Valid values are: 
            Device
            User
    .PARAMETER Exclusion
        Specifies whether to create an exclusion group. 
        
        Valid values are: 
            Yes
            Both
    .EXAMPLE
        New-IntuneEndpointSecurityGroup -Entity 'Antivirus' -OperatingSystem 'Windows' -AVSetting 'Defender Antivirus Configuration' -Purpose 'Baseline' -DeploymentTarget 'Device' -Exclusion 'Both'

        Creates an Endpoint Security group and an exclusion group for the specified settings.
    .EXAMPLE
        New-IntuneEndpointSecurityGroup -Entity 'Disk Encryption' -OperatingSystem 'MacOS' -DESetting 'FileVault' -Purpose 'Baseline' -DeploymentTarget 'User'

        Creates an Endpoint Security group for the Disk Encryption FileVault setting, targeting users.
    .EXAMPLE
        New-IntuneEndpointSecurityGroup -Entity 'Firewall' -OperatingSystem 'Windows' -FWSetting 'Windows Firewall Rules' -Purpose 'Microsoft SQL' -DeploymentTarget 'Device'
        
        Creates an Endpoint Security group for the Firewall Windows Firewall Rules setting, targeting devices.
    .EXAMPLE
        New-IntuneEndpointSecurityGroup -Entity 'Endpoint Detection and Response' -OperatingSystem 'Linux' -EDRSetting 'Endpoint Detection and Response' -Purpose 'Onboarding' -DeploymentTarget 'Device' -Exclusion 'Yes'
        
        Creates an exclusion group for the Endpoint Detection and Response setting, targeting devices.
    .EXAMPLE
        New-IntuneEndpointSecurityGroup -Entity 'Application Control for Business' -OperatingSystem 'Windows' -ACBSetting 'Configuration' -Purpose 'Baseline' -DeploymentTarget 'User' -Exclusion 'Both'
    
        Creates an Endpoint Security group and an exclusion group for the Application Control for Business Configuration setting, targeting users.
    .EXAMPLE
        New-IntuneEndpointSecurityGroup -Entity 'Attack Surface Reduction' -OperatingSystem 'Windows' -ASRSetting 'Exploit Protection' -Purpose 'Regulator' -DeploymentTarget 'Device'

        Creates an Endpoint Security group for the Attack Surface Reduction Exploit Protection setting, targeting devices.
    .NOTES
        Name:           New-IntuneEndpointSecurityGroup.ps1
        Author:         Ahnamataeus Vex
        Version:        1.0.0
        Release Date:   2024-09-10
    #>

    [CmdletBinding(DefaultParameterSetName = 'Antivirus')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Antivirus', 'Disk Encryption', 'Firewall', 'Endpoint Privilege Management', 'Endpoint Detection and Response', 'Application Control for Business', 'Attack Surface Reduction', 'Account Protection', 'Device Compliance')]
        [string]$Entity,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Windows', 'MacOS', 'Linux', 'Android', 'iOS')]
        [string]$OperatingSystem,

        [Parameter(Mandatory = $true, ParameterSetName = 'Antivirus')]
        [ValidateSet('Defender Update Controls', 'Defender Exclusions', 'Defender Antivirus Configuration', 'Windows Security Experience')]
        [string]$AVSetting,

        [Parameter(Mandatory = $true, ParameterSetName = 'Disk Encryption')]
        [ValidateSet('BitLocker', 'FileVault')]
        [string]$DESetting,

        [Parameter(Mandatory = $true, ParameterSetName = 'Firewall')]
        [ValidateSet('Windows Firewall Rules', 'Windows Firewall Configuration', 'Windows Hyper-V Firewall Rules', 'MacOS Firewall')]
        [string]$FWSetting,

        [Parameter(Mandatory = $true, ParameterSetName = 'Endpoint Privilege Management')]
        [ValidateSet('Elevation Rules Policy', 'Elevation Rules Settings')]
        [string]$EPMSetting,

        [Parameter(Mandatory = $true, ParameterSetName = 'Endpoint Detection and Response')]
        [ValidateSet('Endpoint Detection and Response')]
        [string]$EDRSetting,

        [Parameter(Mandatory = $true, ParameterSetName = 'Application Control for Business')]
        [ValidateSet('Configuration')]
        [string]$ACBSetting,

        [Parameter(Mandatory = $true, ParameterSetName = 'Attack Surface Reduction')]
        [ValidateSet('App and Browser Isolation', 'Attack Surface Reduction Rules', 'Device Control', 'Exploit Protection', 'Application Control')]
        [string]$ASRSetting,

        [Parameter(Mandatory = $true, ParameterSetName = 'Account Protection')]
        [ValidateSet('Account Protection', 'Local Admin Password Solution', 'Local User Group Membership')]
        [string]$ACTPSetting,

        [Parameter(Mandatory = $true, ParameterSetName = 'Device Compliance')]
        [ValidateSet('Personally-owned', 'Corporate')]
        [string]$DCSetting,

        [Parameter(Mandatory = $true)]
        [string]$Purpose,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Device', 'User')]
        [string]$DeploymentTarget,

        [Parameter()]
        [ValidateSet('Yes', 'Both')]
        [string]$Exclusion
    )

    If (!(Get-MgContext)) {
        Connect-MgGraph -NoWelcome
    }

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

    # Clean up Purpose
    $Purpose = Clean-String -String $Purpose

    # Hash tables for mappings
    $osValues = @{
        'Windows' = 'Win'
        'MacOS' = 'Mac'
        'Linux' = 'Lnx'
        'Android' = 'Drd'
        'iOS' = 'iOS'
    }

    $entityValues = @{
        'Antivirus' = 'AV'
        'Disk Encryption' = 'DE'
        'Firewall' = 'FW'
        'Endpoint Privilege Management' = 'EPM'
        'Endpoint Detection and Response' = 'EDR'
        'Application Control for Business' = 'ACB'
        'Attack Surface Reduction' = 'ASR'
        'Account Protection' = 'ACTP'
        'Device Compliance' = 'DC'
    }

    $settingValues = @{
        'Antivirus' = $AVSetting
        'Disk Encryption' = $DESetting
        'Firewall' = $FWSetting
        'Endpoint Privilege Management' = $EPMSetting
        'Endpoint Detection and Response' = $EDRSetting
        'Application Control for Business' = $ACBSetting
        'Attack Surface Reduction' = $ASRSetting
        'Account Protection' = $ACTPSetting
        'Device Compliance' = $DCSetting
    }

    $unsupportedOS = @{
        'Antivirus' = @('Android', 'iOS')
        'Disk Encryption' = @('Linux', 'Android', 'iOS')
        'Firewall' = @('Linux', 'Android', 'iOS')
        'Endpoint Privilege Management' = @('MacOS', 'Linux', 'Android', 'iOS')
        'Endpoint Detection and Response' = @('Android', 'iOS')
        'Application Control for Business' = @('MacOS', 'Linux', 'Android', 'iOS')
        'Attack Surface Reduction' = @('MacOS', 'Linux', 'Android', 'iOS')
        'Account Protection' = @('MacOS', 'Linux', 'Android', 'iOS')
        'Device Compliance' = @('MacOS', 'Linux', 'iOS')
    }

    If ($OperatingSystem -in $unsupportedOS[$Entity]) {
        Write-Error "$Entity is not supported on $OperatingSystem."
        return
    }

    # Construct the group name
    $OSValue = $osValues[$OperatingSystem]
    $EntityValue = $entityValues[$Entity]
    $SettingValue = $settingValues[$Entity]
    $TargetValue = If ($DeploymentTarget -eq 'Device') { 'D' } Else { 'U' }

    $GroupName = Clean-String -String "MEM-$OSValue-ES-$EntityValue-$SettingValue-$Purpose-$TargetValue"
    $compiledDesc = "Endpoint Security group for the $SettingValue $Entity setting, targeting $($DeploymentTarget.ToLower() + 's')."

    If ($Exclusion -eq 'Yes' -or $Exclusion -eq 'Both') {
        $ExGroupName = Clean-String -String "MEM-$OSValue-ES-$EntityValue-$SettingValue-ExGrp-$Purpose-$TargetValue"
        $ExGroupDesc = "Use for exclusions to the $SettingValue $Entity setting group, targeting $($DeploymentTarget.ToLower() + 's')."

        Write-Output "Exclusion Group Name: $ExGroupName"
        Write-Output "Exclusion Description: $ExGroupDesc"

        # Add logic to create the exclusion group using Graph API
        $exGroupParams = @{
            DisplayName = $ExGroupName
            Description = $ExGroupDesc
            MailEnabled = $false
            MailNickname = 'NotSet'
            SecurityEnabled = $true
        }

        Try {
            $exGroup = New-MgBetaGroup @exGroupParams
            Write-Output "Exclusion group created successfully: $($exGroup.Id)"
        } Catch {
            Write-Error "Failed to create exclusion group: $_"
        }
    }

    If ($Exclusion -ne 'Yes') {
        Write-Output "Group Name: $GroupName"
        Write-Output "Description: $compiledDesc"

        # Add logic to create the group using Graph API
        $groupParams = @{
            DisplayName = $GroupName
            Description = $compiledDesc
            MailEnabled = $false
            MailNickname = 'NotSet'
            SecurityEnabled = $true
        }

        Try {
            $group = New-MgBetaGroup @groupParams
            Write-Output "Group created successfully: $($group.Id)"
        } Catch {
            Write-Error "Failed to create group: $_"
        }
    }
}
