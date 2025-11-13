<#
.SYNOPSIS
    Active pre-defined PIM roles.
.DESCRIPTION
    This function will connect the user to AzureAD via the AzureADPreview module. The module is installed if it
    is missing, and if the regular AzureAD module is loaded it will be unloaded so the Preview module can be
    loaded. The module installs for the system, not the CurrentUser. It may be altered at a later date for that.
    There are some roles populated (without their tenant-unique IDs) as an examples, be sure to update them.

    It will fetch the ObjectID of the specified user, and activate the role for the requested amount of hours.

    Don't forget to refresh your browser windows. :)
.PARAMETER Username
    Specify the Username you would like to elevate the role for. It is best to be specific, such as the exact
    UPN.
.PARAMETER Role
    Specify the PIM role you would like to activate. The list is limited to a validated set, and GUIDs are
    unique to each tenant. More can be added as needed. The role GUIDs can be retreived with the following cmdlet
    in your tenant:
    
    Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $resourceID | Where-Object {$_.DisplayName -eq 'Azure Role Name'}
.PARAMETER Hours
    Specify the amount of hours to activate the role for. Code-limited to 6, because you should be forced to 
    check it out twice a day, you lazy gits.
.PARAMETER Reason
    Specify the reason you are activating the role. Some PIMs require a reason, so we will just require it
    for all.
.PARAMETER Verbose
    The function has extensive commenting that can be invoked with -Verbose.
.EXAMPLE
    PS C:\> Activate-PIMRole -Username 'JDoe@contoso.onmicrosoft.com' -Role 'Intune Administrator' -Hours 6 -Reason 'Intune work.' -Verbose
    
    This activates the Intune Administrator role for 'JDoe@contso.onmicrosoft.com' for 6 hours.
.NOTES
    Name:           Activate-PIMRole.ps1
    Author:         Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2022-12-09
    Updated:
        Version 1.0.1: 2022-12-09
            - Added the help section.
            - Added the Reason as a parameter. Meant to do it initially and forgot.
        Version 1.0.2: 2022.12.12
            - Matched up the mixed verbiage to Microsoft's nomenclature: "Activate" (Thanks Jason!)
    To-Do:
        Build out unique hour ranges per role, so some can be more restrictive than others. E.g., 2 hours max
        checkout for a role.
#>

Function Activate-PIMRole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "What is the UPN of the user you're activating the role for?")]
        [string]
        $Username,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Intune Administrator','User Administrator','Conditional Access Administrator','Windows 365 Administrator')]
        [string]
        $Role,
        [Parameter(Mandatory = $true, HelpMessage = 'How many hours to activate the role out for? Valid value are 1-6.')]
        [ValidateRange (1,6)]
        [int]
        $Hours,
        [Parameter(Mandatory = $true)]
        [string]
        $Reason
    )

    # Define the Tenant ID
    $resourceID = "tenant-guid-here"

    # Define the Azure role names, and their associated IDs
    # This can be retreived with the following cmdlet:
    #    Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $resourceID | Where-Object {$_.DisplayName -eq 'Azure Role Name'}
    $roleGUIDs = @{
        'Intune Administrator' = 'role-guid-here'
        'User Administrator' = 'role-guid-here'
        'Conditional Access Administrator' = 'role-guid-here'
        'Windows 365 Administrator' = 'role-guid-here'
        'Application Administrator' = 'role-guid-here'
    }
    $roleGUIDs.Keys | ForEach-Object { If ($_ -eq $Role) { $roleDefinitionID = $($roleGUIDs[$_]) } }

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
    
    # Make sure AzureADPreview is installed, loaded, and Azure is connected via Connect-AzureAD
    Install-AzureADPreviewModule

    # Get the ObjectID of the user and write it to the $subjectID variable
    Write-Verbose 'Searching Azure for the user account.'
    $subjectID = (Get-AzureADUser -SearchString $Username).ObjectId

    # Validate a result was returned
    If ($null -eq $subjectID) {
        Write-Warning 'User account not found. Verify the username.'
        break
    }
    ElseIf ($subjectID.Count -gt 1) {
        Write-Warning 'Multiple accounts found. Further define your Username.'
        break
    }
    Else {
        Write-Verbose 'Account found.'
    }

    # Set the schedule for the activation, with the hours defined
    Write-Verbose "Defining the activationschedule, for a $Hours hour window."
    $date = Get-Date
    Try {
        $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Warning 'Unable to create the schedule. Please validate that the AzureADPreview module is installed and imported, instead of the AzureAD module.'
        break
    }
    $schedule.Type = "Once"
    $schedule.StartDateTime = $date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.endDateTime = $date.AddHours($Hours).ToUniversalTime().ToSTring("yyyy-MM-ddTHH:mm:ss.fffZ")

    # Activate the role
    Write-Verbose "Activating the $Role role out for $Hours hours."
    Try {
        Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $resourceID -RoleDefinitionId $roleDefinitionID -SubjectId $subjectID -Type 'UserAdd' -AssignmentState 'Active' -Schedule $schedule -Reason $Reason
    }
    Catch {
        Write-Warning 'Activating the role out failed.'
        break
    }
}