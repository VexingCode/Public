Function New-IntunePolicyGroup {

    <#
    .SYNOPSIS
        Function to standardize the creation of Policy groups for Intune.
    .DESCRIPTION
        This function will create the group with a naming prefix and a standardized description.
    .PARAMETER OperatingSystem
        Mandatory parameter to specify the operating system this application is built and 
        deployed for.

        This parameter is a validated set, and the options are (Friendly Name = Value):
            Windows = Win
            Android = Drd
            MacOS = MacOS
            iOS/iPadOS = iOS
    .PARAMETER DeploymentTarget
        Parameter to specify your deployment target for the group.

        This parameter is a validated set, and the options are:
            Device
            User
            Both
    .PARAMETER ProductName
        Mandatory parameter to specify the product name.

        NOTE: Do not worry about using special characters, as the script will strip them out.
        Spaces will be replaced with hyphens.
    .PARAMETER PolicyName
        Parameter to specify the policy name of the group.
    .PARAMETER ExclusionGroup
        Optional parameter to specify if you want the function to create an exclusion group or
        not. If the parameter is not specified, no exclusion group is created. 
        
        This parameter is a validated set, and the options are:
            Yes = Only an exclusion group will be created. Use this if you already created
            a deployment group of the same type
            Both = A deployment group, and an exclusion group will be created at the same time
    .EXAMPLE
        C:\> New-IntunePolicyGroup -OperatingSystem Win -DeploymentTarget Device -ProductName "Windows" -PolicyName "Baseline"

        This will create a policy group with the following information:

        Group Name: MEM-Win-Pol-Windows-Baseline-D
        Group Description: "Group targeting devices, for the Windows Baseline policy.
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateSet('Win','Drd','MacOS','iOS')]
        [string]
        $OperatingSystem,

        [Parameter(Mandatory,Position=1)]
        [ValidateSet('Device','User','Both')]
        [string]
        $DeploymentTarget,

        [Parameter(Mandatory,Position=2)]
        [string]
        $ProductName,

        [Parameter(Mandatory,Position=3)]
        [string]
        $PolicyName,

        [Parameter(Position=4)]
        [ValidateSet('Yes','Both')]
        [string]
        $ExclusionGroup
    )

    If (!(Get-MgContext)) {
        Connect-MgGraph -NoWelcome
    }

    Function Clean-String {
        param ([string]$InputString)

        $cleanedString = $InputString.Trim()
        $cleanedString = $cleanedString -replace '[^a-zA-Z0-9\s-]', ''
        $cleanedString = $cleanedString -replace '\s*-\s*', '-'
        $cleanedString = $cleanedString -replace '-+', '-'
        $cleanedString = $cleanedString -replace '\s+', '-'

        return $cleanedString
    }

    $cleanName   = Clean-String -InputString $ProductName
    $cleanPolicy = Clean-String -InputString $PolicyName

    $deploymentTargets = If ($DeploymentTarget -eq 'Both') { 'Device', 'User' } Else { $DeploymentTarget }

    $targetMappings = @{
        'Device' = @{ Name = 'D'; Desc = 'devices' }
        'User'   = @{ Name = 'U'; Desc = 'users' }
    }

    ForEach ($tgt in $deploymentTargets) {
        $nameTgt = $targetMappings[$tgt].Name
        $descTgt = $targetMappings[$tgt].Desc

        $compiledName   = "MEM-$OperatingSystem-Pol-$cleanName-$cleanPolicy-$nameTgt"
        $compiledDesc   = "Group targeting $descTgt, for the $ProductName $PolicyName policy."

        $compiledNameEx = "MEM-$OperatingSystem-Pol-$cleanName-$cleanPolicy-ExGrp-$nameTgt"
        $compiledDescEx = "Exclusion group targeting $descTgt, for the $ProductName $PolicyName policy."

        $Body = @{
            DisplayName     = $compiledName
            Description     = $compiledDesc
            MailEnabled     = $false
            MailNickname    = 'NotSet'
            SecurityEnabled = $true
        }

        $BodyEx = @{
            DisplayName     = $compiledNameEx
            Description     = $compiledDescEx
            MailEnabled     = $false
            MailNickname    = 'NotSet'
            SecurityEnabled = $true
        }

        If ($ExclusionGroup -eq 'Yes') {
            New-MgBetaGroup -Body $BodyEx
        } ElseIf ($ExclusionGroup -eq 'Both') {
            New-MgBetaGroup -Body $Body
            New-MgBetaGroup -Body $BodyEx
        } Else {
            New-MgBetaGroup -Body $Body
        }
    }
}