Function Invoke-PIMRoleActivation{
    <#
    .SYNOPSIS
        Function to check out a PIM role for a user in Microsoft Entra ID (Azure AD) using Microsoft Graph Beta.
    .DESCRIPTION
        This function activates a PIM role for a user in Microsoft Entra ID (Azure AD) using Microsoft Graph Beta.
        It requires the user to have the necessary permissions and the role to be eligible for activation.
    .PARAMETER Username
        The user principal name (UPN) of the user for whom the PIM role is being activated.
    .PARAMETER Role
        The name of the PIM role to be activated. Valid values are 'Intune Administrator', 'Authentication Administrator', 'Global Reader', 'Security Reader', 'User Administrator', 'Conditional Access Administrator', and 'Windows 365 Administrator'.
    .PARAMETER Hours
        The number of hours for which the role should be activated. Valid range is from 1 to 6 hours.
    .PARAMETER Reason
        The reason for activating the PIM role.
    .EXAMPLE
        Invoke-PIMRoleActivation -Username 'Jack@RepairmanJack.com' -Role 'Intune Administrator' -Hours 2 -Reason 'Need to manage Intune policies for a new device.'
        This command activates the 'Intune Administrator' role for the user 'Jack@Repairman
    #>



    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Username,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Intune Administrator','Authentication Administrator','Global Reader','Security Reader','User Administrator','Conditional Access Administrator','Windows 365 Administrator')]
        [string] $Role,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1,6)]
        [int] $Hours,

        [Parameter(Mandatory = $true)]
        [string] $Reason
    )

    $resourceID = "78e61e45-6beb-4009-8f99-359d8b54f41b" # CoS Tenant Id

    $roleGUIDs = @{
        'Authentication Administrator' = 'c4e39bd9-1100-46d3-8c65-fb160da0071f'
        'Conditional Access Administrator' = 'b1be1c3e-b65d-4f19-8427-f6fa0d97feb9'
        'Global Reader' = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
        'Intune Administrator' = '3a2c62db-5318-420d-8d74-23affee5d9d5'
        'Security Reader' = '5d6b6bb7-de71-4623-b4af-96380a352509'
        'User Administrator' = 'fe930be7-5e62-47db-91af-98c3a49a38b1'
        'Windows 365 Administrator' = '11451d60-acb2-45eb-a7d6-43d0f0125c13'
    }
    $roleDefinitionID = $roleGUIDs[$Role]

    Function New-MgGraphConnection {
        $requiredModules = @(
            'Microsoft.Graph.Beta.Identity.Governance',
            'Microsoft.Graph.Beta.Users'
        )

        ForEach ($module in $requiredModules) {
            If (-not (Get-Module -ListAvailable -Name $module)) {
                Write-Output "Installing missing module: $module"
                Try {
                    Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
                    Write-Output "Successfully installed $module"
                }
                Catch {
                    Write-Warning "Failed to install $module`: $_"
                    return
                }
            }
            Try {
                Import-Module -Name $module -Force -ErrorAction Stop
                Write-Output "Imported module: $module"
            }
            Catch {
                Write-Warning "Failed to import $module`: $_"
                return
            }
        }

        Try {
            Connect-MgGraph -NoWelcome -ErrorAction Stop
            Write-Output "Connected to Microsoft Graph Beta"
        }
        Catch {
            Write-Warning "Failed to connect to Microsoft Graph Beta: $_"
            return
        }
    }

    If (!(Get-MgContext)) {
        New-MgGraphConnection
    } Else {
        Write-Output 'Using existing Microsoft Graph Beta connection.'
    }

    Write-Output "Searching for user $Username..."
    $user = Get-MgBetaUser -Filter "userPrincipalName eq '$Username'" -ErrorAction SilentlyContinue

    If (-not $user) {
        Write-Warning "User '$Username' not found."
        break
    }

    $subjectId = $user.Id

    $startTime = (Get-Date).ToUniversalTime()
    $endTime = $startTime.AddHours($Hours)

    $body = @{
        RoleDefinitionId = $roleDefinitionID
        ResourceId       = $resourceID
        SubjectId        = $subjectID
        AssignmentState  = 'Active'
        Type             = 'UserAdd'
        Reason           = $Reason
        Schedule         = @{
            Type           = 'Once'
            StartDateTime  = $startTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            EndDateTime    = $endTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }

    Try {
        New-MgBetaPrivilegedAccessRoleAssignmentRequest -PrivilegedAccessId 'aadRoles' -BodyParameter $body
    }
    Catch {
        Write-Warning "Role activation failed: $_"
        break
    }
}