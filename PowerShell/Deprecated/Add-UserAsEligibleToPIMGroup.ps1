Function Add-UserAsEligibleToPIMGroup {
    <#
    .SYNOPSIS
        This function will add a user as "eligible" to activate membership into a PIM Group.
    .DESCRIPTION
        With the introduction of PIM groups, we can now assign multiple roles (including roles not from
        AzureAD, such as Intune) to a group and make users eligible to activate membership to that group.

        When they activate the membership, it will drop them into the group in question, and grant them
        the roles that have been added there. When their PIM timer runs out, it removes those role
        permissions.

        The account/service being used to run this script must have the authority to edit PIM groups.
    .PARAMETER GroupName
        Specify the name of the group you wish to grant the eligible PIM permission to.
    .PARAMETER UserPrincipalName
        Specify the User Principal Name of the user you wish to have PIM added to. Since the UPN is
        unique, we are relying on this rather than the SAMAccountName, or usernames, for synced accounts.
    .EXAMPLE
        PS C:\> Add-UserAsEligibleToPIMGroup -GroupName 'PIM-RBAC-Helpdesk-Tier-1' -UserPrincipalName 'ADMDoeJohn@contoso.onmicrosoft.com'
        
        This adds 'ADMDoeJohn@contoso.onmicrosoft.com' as an account eligible to activate membership into the
        'PIM-RBAC-Helpdesk-Tier-1' group.
    .NOTES
        Name:           Add-UserAsEligibleToPIMGroup.ps1
        Author:         Ahnamataeus Vex
        Version:        1.0.0
        Release Date:   2023-03-08
        To-Do:
            Validate that the group is PIM enabled
            Validate that the user is not already a member
            Perhaps refresh membership if they are a member, but < X days left
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $GroupName,
        [Parameter(Mandatory = $true)]
        [string]
        $UserPrincipalName
    )

    # Ensure the AzureADPreview module is installed and loaded
    Function Install-AzureADPreviewModule {
        Write-Verbose 'Validating if the standard AzureAD module is imported...'
        If (Get-Module -Name AzureAD) {
            Write-Verbose 'AzureAD is imported; removing it.'
            Disconnect-AzureAD
            Remove-Module -Name AzureAD
        }
        Else {
            Write-Verbose 'The AzureAD module is not imported. Proceeding...'
        }
    
        Write-Verbose 'Grabbing the version of AzureADPreview from the gallery...'
        $GalleryModuleVersion = (Find-Module -Name AzureADPreview).Version
        Write-Verbose "Gallery version is: $GalleryModuleVersion"
        Write-Verbose 'Grabbing the version of AzureADPreview that is installed (if any)...'
        $InstalledModuleVersion = (Get-InstalledModule AzureADPreview -ErrorAction SilentlyContinue).Version
        If ($null -eq $InstalledModuleVersion) {
            $InstalledModuleVersion = 'Not installed.'
        }
        Write-Verbose "Installed version is: $InstalledModuleVersion"
        Write-Verbose 'Comparing the two to see if the gallery is newer...'
        If (!($InstalledModuleVersion -ge $GalleryModuleVersion)) {
            Write-Verbose 'Gallery version is newer, or its not installed.'
            Write-Verbose 'Installing the AzureADPreview module.'
            Install-Module AzureADPreview -Force -AllowClobber
            Write-Verbose 'Importing the AzureADPreview module...'
            Import-Module AzureADPreview -Force
            Write-Verbose 'Connecting to AzureADPreview. Please ensure you are using a privileged account.'
            Try {
                Connect-AzureAD -ErrorAction Stop | Out-Null
            }
            Catch {
                Write-Warning 'Failed to Connect-AzureAD.'
                break
            }
        }
        Else {
            Write-Verbose 'AzureADPreview module is current.'
            If (!(Get-Module -Name AzureADPreview)) {
                Import-Module -Name AzureADPreview -Force
            }
            Try {
                $aadConnectionCheck = Get-AzureADTenantDetail
                $tenant = $aadConnectionCheck.DisplayName
                Write-Verbose "AzureAD already connected to: $tenant"
                Write-Verbose "Skipping connection step."
            } 
            Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] {
                Write-Verbose 'Connecting to AzureAD. Please ensure you are using a privileged account.'
                Try {
                    Connect-AzureAD -ErrorAction Stop | Out-Null
                }
                Catch {
                    Write-Warning 'Failed to Connect-AzureAD.'
                    break
                }
            }
        }
    }

    # Get the GroupID
    $groupID = (Get-AzureADGroup -Filter "displayName eq '$GroupName'").ObjectID

    # Get Role definition; there are two definitions on the groups, and we want to make sure we are grabbing "Member"
    $roleDefinitionID = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId "aadGroups" -ResourceId $groupID -Filter "displayName eq 'Member'").ID

    # Get User's ObjectID based on their UPN
    $targetUserID = (Get-AzureADUser -Filter "userPrincipalName eq '$upn'").ObjectID

    # Set the schedule for a year; this is the longest that they can be assigned the PIM privilege
    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule -ErrorAction SilentlyContinue
    $schedule.Type = "Once"
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.EndDateTime =  ((Get-Date).AddDays(365)).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    # Create the eligible role assignment, for the user, on the specified group
    Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadGroups' -ResourceId $groupID -RoleDefinitionId $roleDefinitionID -SubjectId $targetuserID -Type 'adminAdd' -AssignmentState 'Eligible' -schedule $schedule -reason "testing"
}