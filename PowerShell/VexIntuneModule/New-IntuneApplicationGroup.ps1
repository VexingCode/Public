Function New-IntuneApplicationGroup {

    <#
    .SYNOPSIS
        Function to standardize the creation of Application deployment groups for Intune.
    .DESCRIPTION
        This function facilitates the creation of standardized groups for Application
        deployments in Intune. It can create "Required" (AIR) and "Available" (AIA) install
        groups, as well as "Update" (AUD) and "Uninstall" (AUR) groups. Additionally, it
        can create exclusion groups (ExGrp) for each of those.
    .PARAMETER ProductVendor
        Mandatory parameter to specify the product vendor.
        
        NOTE: Do not worry about using special characters, as the script will strip them out.
        Spaces will be replaced with hyphens.
    .PARAMETER ProductName
        Mandatory parameter to specify the product name.

        NOTE: Do not worry about using special characters, as the script will strip them out.
        Spaces will be replaced with hyphens.
    .PARAMETER DeploymentType
        Mandatory parameter to specify which type of deployment group you would like to create. 
        It also has the option of creating all deployment type groups, if needed (unlikely).

        This parameter is a validated set, and the options are:
            Available Install
            Required Install
            Update
            Available Uninstall
            Required Uninstall
            All
    .PARAMETER DeploymentTarget
        Mandatory parameter to specify your deployment target for the group. It also has the 
        option of creating all deployment target groups, if needed.

        This parameter is a validated set, and the options are:
            Device
            User
            Both
    .PARAMETER OperatingSystem
        Mandatory parameter to specify the operating system this application is built and 
        deployed for.

        This parameter is a validated set, and the options are (Friendly Name = Value):
            Windows = Win
            Android = Drd
            MacOS = MacOS
            iOS/iPadOS = iOS
    .PARAMETER ExclusionGroup
        Optional parameter to specify if you want the function to create an exclusion group or
        not.  If the parameter is not specified, no exclusion group is created. 
        
        This parameter is a validated set, and the options are:
            Yes = Only an exclusion group will be created. Use this if you already created
            a deployment group of the same type
            Both = A deployment group, and an exclusion group will be created at the same time
    .EXAMPLE
        C:\> New-IntuneApplicationGroup -ProductVendor 'Contoso Co.' -ProductName 'Example Program' -DeploymentType Required -DeploymentTarget Device -OperatingSystem Win (-ExclusionGroup Both)

        This will create a required deployment group, targeting devices, for the product specified.
        The end result(s) will appear as below:

        Group name: MEM-Win-AIR-Contoso-Co-Example-Program-D
        Group description: Required install group targeting devices, for the Contoso Co. Example Program application.

        If the "-ExclusionGroup Both" parameter|value is specified, the below group will also be
        created:

        Group name: MEM-Win-AIR-ExGrp-Contoso-Co-Example-Program-D
        Group description: Use for exclusions to the required install group targeting devices, for the Contoso Co. Example Program application.
    .EXAMPLE
        C:\> New-IntuneApplicationGroup -ProductVendor 'Contoso Co.' -ProductName 'Example Program' -DeploymentType Available -DeploymentTarget User -OperatingSystem Win (-ExclusionGroup Both)

        This will create an available deployment group, targeting users, for the product specified.
        The end result(s) will appear as below:

        Group name: MEM-Win-AIA-Contoso-Co-Example-Program-U
        Group description: Available install group targeting users, for the Contoso Co. Example Program application.

        If the "-ExclusionGroup Both" parameter|value is specified, the below group will also be
        created:
        
        Group name: MEM-Win-AIA-ExGrp-Contoso-Co-Example-Program-U
        Group description: Use for exclusions to the available install group targeting users, for the Contoso Co. Example Program application.
    .EXAMPLE
        C:\> New-IntuneApplicationGroup -ProductVendor 'Contoso Co.' -ProductName 'Example Program' -DeploymentType Update -DeploymentTarget Device -OperatingSystem Win (-ExclusionGroup Both)

        This will create a required update deployment group, targeting devices, for the product specified.
        The end result(s) will appear as below:

        Group name: MEM-Win-AUP-Contoso-Co-Example-Program-D
        Group description: Required update group targeting devices, for the Contoso Co. Example Program application.

        If the "-ExclusionGroup Both" parameter|value is specified, the below group will also be
        created:
        
        Group name: MEM-Win-AUP-ExGrp-Contoso-Co-Example-Program-D
        Group description: Use for exclusions to the required update group targeting devices, for the Contoso Co. Example Program application.
    .EXAMPLE
        C:\> New-IntuneApplicationGroup -ProductVendor 'Contoso Co.' -ProductName 'Example Program' -DeploymentType Uninstall -DeploymentTarget Device -OperatingSystem Win (-ExclusionGroup Both)

        This will create a required uninstall deployment group, targeting devices, for the product specified.
        The end result(s) will appear as below:

        Group name: MEM-Win-AUR-Contoso-Co-Example-Program-D
        Group description: Required uninstall group targeting devices, for the Contoso Co. Example Program application.

        If the "-ExclusionGroup Both" parameter|value is specified, the below group will also be
        created:
        
        Group name: MEM-Win-AUR-ExGrp-Contoso-Co-Example-Program-D
        Group description: Use for exclusions to the required uninstall group targeting devices, for the Contoso Co. Example Program application.
    .EXAMPLE
        C:\> New-IntuneApplicationGroup -ProductVendor 'Contoso Co.' -ProductName 'Example Program' -DeploymentType Required -DeploymentTarget Both -OperatingSystem Win (-ExclusionGroup Both)

        This will create required install deployment groups, targeting devices and users, for the product specified.
        The end result(s) will appear as below:

        Group name: MEM-Win-AIR-Contoso-Co-Example-Program-D
        Group description: Required install group targeting devices, for the Contoso Co. Example Program application.

        Group name: MEM-Win-AIR-Contoso-Co-Example-Program-U
        Group description: Required install group targeting users, for the Contoso Co. Example Program application.

        If the "-ExclusionGroup Both" parameter|value is specified, the below group will also be
        created:

        Group name: MEM-Win-AIR-ExGrp-Contoso-Co-Example-Program-D
        Group description: Use for exclusions to the required install group targeting devices, for the Contoso Co. Example Program application.

        Group name: MEM-Win-AIR-ExGrp-Contoso-Co-Example-Program-U
        Group description: Use for exclusions to the required install group targeting users, for the Contoso Co. Example Program application.
    .NOTES
        Name:           New-IntuneApplicationGroup.ps1
        Author:         Ahnamataeus Vex
        Version:        1.0.0
        Release Date:   2024-09-05
            Updated:
                Version 1.0.1: 2024-09-05
                    - Streamlined the function
                Version 1.0.2: 2024-09-10
                    - Added the help section
                    - Fixed typo in #Requires statement
                    - Fixed typo in the Exclusion Group description creation.
                Version 1.0.3: 2024-09-10
                    - Updated the Clean-String function to account for some other scenarios that
                    could happen
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]
        $ProductVendor,
        [Parameter(Mandatory,Position=1)]
        [string]
        $ProductName,
        [Parameter(Mandatory,Position=2)]
        [ValidateSet('Available Install','Required Install','Update','Available Uninstall','Required Uninstall','All')]
        [string]
        $DeploymentType,
        [Parameter(Mandatory,Position=3)]
        [ValidateSet('Device','User','Both')]
        [string]
        $DeploymentTarget,
        [Parameter(Mandatory,Position=4)]
        [ValidateSet('Win','Drd','MacOS','iOS')]
        [string]
        $OperatingSystem,
        [Parameter(Position=5)]
        [ValidateSet('Yes','Both')]
        [string]
        $ExclusionGroup
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

    $cleanVendor = Clean-String -InputString $ProductVendor
    $cleanName = Clean-String -InputString $ProductName

    $deploymentTypes = If ($DeploymentType -eq 'All') { 'Available Install','Required Install','Update','Available Uninstall','Required Uninstall' } Else { $DeploymentType }
    $deploymentTargets = If ($DeploymentTarget -eq 'Both') { 'Device', 'User' } Else { $DeploymentTarget }

    $typeMappings = @{
        'Available Install'     = @{ Name = 'AIA'; Desc = 'Available install' }
        'Required Install'      = @{ Name = 'AIR'; Desc = 'Required install' }
        'Update'                = @{ Name = 'AUP'; Desc = 'Required update' }
        'Available Uninstall'   = @{ Name = 'AUA'; Desc = 'Available uninstall' }
        'Required Uninstall'    = @{ Name = 'AUR'; Desc = 'Required uninstall' }
    }

    $targetMappings = @{
        'Device' = @{ Name = 'D'; Desc = 'devices' }
        'User'   = @{ Name = 'U'; Desc = 'users' }
    }

    ForEach ($dt in $deploymentTypes) {
        $nameDT = $typeMappings[$dt].Name
        $descDT = $typeMappings[$dt].Desc

        ForEach ($tgt in $deploymentTargets) {
            $nameTgt = $targetMappings[$tgt].Name
            $descTgt = $targetMappings[$tgt].Desc

            # Generate new group body
            $compiledName = "MEM-$OperatingSystem-$nameDT-$cleanVendor-$cleanName-$nameTgt"
            $compiledDesc = "$descDT group targeting $descTgt, for the $ProductVendor $ProductName application."

            $Body = @{
                DisplayName     = $compiledName
                Description     = $compiledDesc
                MailEnabled     = $false
                MailNickname    = 'NotSet'
                SecurityEnabled = $true
            }

            # Generate new exclusion group body
            $compiledNameEx = "MEM-$OperatingSystem-$nameDT-$cleanVendor-$cleanName-ExGrp-$nameTgt"
            $compiledDescEx = "Use for exclusions to the $($descDT.ToLower()) group targeting $descTgt, for the $ProductVendor $ProductName application."

            $BodyEx = @{
                DisplayName     = $compiledNameEx
                Description     = $compiledDescEx
                MailEnabled     = $false
                MailNickname    = 'NotSet'
                SecurityEnabled = $true
            }

            If ($ExclusionGroup -eq 'Yes') {
                # Create new group
                New-MgBetaGroup -Body $BodyEx
            } ElseIf ($ExclusionGroup -eq 'Both') {
                # Create new group
                New-MgBetaGroup -Body $Body
                # Create new exclusion group
                New-MgBetaGroup -Body $BodyEx
            } Else {
                # Create new exclusion group
                New-MgBetaGroup -Body $Body
            }
        }
    }
}