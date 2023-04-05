Function Set-UsersAsEligibleToPIMGroup {
<#
.SYNOPSIS
    This script will add, remove, and refesh eligibility to a PIM group based on membership
    to another group.
.DESCRIPTION
    The script utilizes two groups, a source group, and a group with PIM Group permissions
    assigned. It will reference the Source group for assigning eligibility to the PIM Group,
    as well as refresh their eligibility timer if they have hit the renewal threshold.

    If they are not in the Source group, or were removed, they will have their eligibility
    revoked.

    The account running this script needs to have the correct permissions to read groups, and 
    assign users to PIM. It also requires the AzureADPreview module.
.PARAMETER SourceGroupName
    Specify the Source Group Name (display name) in Azure. We will pull the eligible users
    from this group.
.PARAMETER PIMGroupName
    Specify the PIM Group that was created with the appropriate roles. The users within the
    Source Group will have eligibility to this group created for them.
.PARAMETER EligibleTimeFrame
    Specify how long the eligibility lasts. PIM eligibility can be assigned for up to 365 days.

    Recommendation: Since this is designed to be run on a schedule (daily), I'd suggest shorter
    timeframes to ensure constant compliance. 7-14 days would be ideal.
.PARAMETER RenewalThreshold
    Specify the amount of days remaining on their eligibility before we automatically renew it
    back to the EligibleTimeFrame.

    Example: If the EligibleTimeFrame is 14 days, and you set the RenewalTimeFrame to 4, it will
    renew when they have 4 days, or less, left.

    Recommendation: I'd ensure that you have a least a couple days buffer, just in case the
    script does not run.
.EXAMPLE
    PS C:\> Set-UsersAsEligibleToPIMGroup -SourceGroupName 'RBAC-Role-Helpdesk' -PIMGroupName 'PIM-Role-Helpdesk' -EligibleTimeframe 14 -RenewalThreshold 7

    In this example, the script will pull the members from 'RBAC-Role-Helpdesk', and add a 14
    day eligible assignment to the PIM Group called 'PIM-Role-Helpdesk'. If the user already has
    an eligibility assignment, but the time remaining is less than or equal to the renewal
    threshold (7 days), it will remove and readd the assignement, thus refreshing the eligibility.
.LINK
    https://github.com/VexingCode/Public/blob/main/PowerShell/Set-UsersAsEligibleToPimGroup.ps1
.NOTES
    Name:           Set-UsersAsEligibleToPIMGroup.ps1
    Author:         Ahnamataeus Vex
    Version:        1.4.0
    Release Date:   2023-04-08
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PIMGroupName,
        [Parameter(Mandatory = $true)]
        [string]
        $SourceGroupName,
        [Parameter(Mandatory = $true)]
        [int]
        $EligibleTimeframe,
        [Parameter(Mandatory = $true)]
        [int]
        $RenewalThreshold
    )

    # Set the schedule
    $currentDate = Get-Date
    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule -ErrorAction SilentlyContinue
    $schedule.Type = "Once"
    $schedule.StartDateTime = $currentDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.EndDateTime =  ($currentDate.AddDays($EligibleTimeFrame)).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

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
    Install-AzureADPreviewModule

    # Get the ObjectId of both groups
    $srcGrpObjId = (Get-AzureADGroup -Filter "displayName eq '$SourceGroupName'").ObjectId
    $pimGrpObjId = (Get-AzureADGroup -Filter "displayName eq '$PIMGroupName'").ObjectId

    # Get the ObjectId's of all members of the Source group
    $srcGrpMembers = (Get-AzureADGroupMember -ObjectId $srcGrpObjId).ObjectId

    # Get the role definition for the PIM group; there are two definitions on the groups, and we want to make sure we are grabbing "Member"
    $roleDefinitionID = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId "aadGroups" -ResourceId $pimGrpObjId -Filter "displayName eq 'Member'").Id

    # Get the assignments on the PIM group that are "Members"; grab SubjectId (user's ObjectId), and EndDateTime (for extending time)
    $pimGrpMembers = Get-AzureADMSPrivilegedRoleAssignment -ProviderId 'aadGroups' -ResourceId $pimGrpObjId -Filter "RoleDefinitionId eq '$roleDefinitionId'" | Select-Object SubjectId, EndDateTime

    # Loop through all of the users within the $pimGrpMembers, and see if they are a member of $srcGrpMembers
    ForEach ($member in $pimGrpMembers.SubjectId) {
        # If the user is not in the Source Group, then we need to remove them
        If ($srcGrpMembers -notcontains $member) {
            # Remove the eligible role assignment, for the user, from the specified group
            Write-Host "$member not found in $SourceGroupName. Removing from PIM eligibility to $PIMGroupName." -ForegroundColor Yellow
            Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadGroups' -ResourceId $pimGrpObjId -RoleDefinitionId $roleDefinitionID -SubjectId $member -Type 'adminRemove' -AssignmentState 'Eligible' -Schedule $schedule -Reason "Automated Remove: User not found in $SourceGroupName. Removing assignment." | Out-Null
        }
    }

    # Loop through all of the users within the $srcGrpMembers, and see if they are a member of $pimGrpMembers
    ForEach ($member in $srcGrpMembers) {
        # If the user is not in the PIM Group eligibility list
        If ($pimGrpMembers.SubjectId -notcontains $member) {
            # Create the eligible role assignment, for the user, on the specified group
            Write-Host "$member found in $SourceGroupName. Creating eligibility to $PIMGroupName." -ForegroundColor Green
            Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadGroups' -ResourceId $pimGrpObjId -RoleDefinitionId $roleDefinitionID -SubjectId $member -Type 'adminAdd' -AssignmentState 'Eligible' -schedule $schedule -reason "Automated Add: User found in $SourceGroupName, but not $PIMGroupName. Adding assignment." | Out-Null
        # If the user is in both, then check their renewal threshold
        } Else {
            # Set the eligible end date, and get the PIM assignment's current EndDateTime
            $eligibleEndDate = $currentDate.AddDays($EligibleTimeframe)
            $currentEndDate = ($pimGrpMembers | Where-Object {$_.SubjectId -eq $member}).EndDateTime

            # If the current assignment is within the Renewal Threshold, or greater than the current date, we need to rectify that
            If ($currentDate.Date -ge $currentEndDate.Date -or $currentEndDate.Date -gt $eligibleEndDate.Date -or (($currentEndDate - $currentDate).Days -le $RenewalThreshold)) {
                # Rectify by removing and readding; you can't seem to just update the elgibility
                Write-Host "Renewal threshold breached. Renewing eligibility to $PIMGroupName for $member." -ForegroundColor Cyan
                # Remove the eligible role assignment, for the user, from the specified group
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadGroups' -ResourceId $pimGrpObjId -RoleDefinitionId $roleDefinitionID -SubjectId $member -Type 'adminRemove' -AssignmentState 'Eligible' -Schedule $schedule -Reason "Automated Refresh (remove): User's assignment is valid, but EndDateTime is greater than $EligibleTimeframe days, or within $RenewalThreshold days of expiry. Removing so we can re-add." | Out-Null
                # Add the eligible role assignment, for the user, from the specified group
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadGroups' -ResourceId $pimGrpObjId -RoleDefinitionId $roleDefinitionID -SubjectId $member -Type 'adminAdd' -AssignmentState 'Eligible' -Schedule $schedule -Reason "Automated Refresh (add): Re-adding the user's eligible assignment." | Out-Null
            }
        }
    }
}