#Requires -Version 5.0
<# #Requires -runasadministrator #>
<#
.SYNOPSIS
    Send a Teams notification on success or failure of OSD.
.DESCRIPTION
    This script will install the PSTeams module, and send a message to Teams. Insert two steps, one under
    the failed OSD section, and one at the end of a successful Task Sequence, with the appropriate parameters.
.PARAMETER WebhookURL
    The URL of the Teams Channel Webhook you would like the message to post to. This parameter is mandatory.
.PARAMETER InOSD
    Specifies that you are running this script from within a Task Sequence, and need to load the TSEnv.
.PARAMETER FailedOSD
    Indicates that the script is being run out of the failed section of OSD, and to grab additional information
    such as the failure message.
.PARAMETER SuccessfulOSD
    Indicates that the script is being run out of the successful section of OSD.
.EXAMPLE
    Send-TeamsOSDNotification -WebhookURL 'https://domain.webhook.office.com/webhookb2/Sup3rGr0ssL0ngW3bh00kURL -InOSD -FailedOSD
    
    This example tells the script you are running it in OSD, and to post a failure message with additional information.
.EXAMPLE
    Send-TeamsOSDNotification -WebhookURL 'https://domain.webhook.office.com/webhookb2/Sup3rGr0ssL0ngW3bh00kURL -InOSD -SuccessfulOSD
    
    This example tells the script you are running it in OSD, and to post a successful message.
.NOTES
        Name:      Send-TeamsOSDNotification.ps1
        Author:    Ahnamataeus Vex
        Credit: Michael Mardahl
            Ideas and script pieces gleaned from: https://msendpointmgr.com/2019/07/10/how-to-notify-a-microsoft-teams-channel-when-a-new-windows-device-has-enrolled-in-microsoft-intune/
        Credit: Terence Beggs
            Ideas and script pieces gleaned from: https://msendpointmgr.com/2017/10/06/configmgr-osd-notification-service-teams/ 
        Version: 1.0.0
        Release Date: 2022-05-02
        To Do:
            - Revamp when we move to Intune
            - Add verbose comments
            - Add Cody Mathis and Adam Cook's Write-CCMLogEntry logging module
            - Somehow condense the Adaptive Card section so its dynamic?
#>

Function Send-TeamsOSDNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $WebhookURL,
        [Parameter()]
        [switch]
        $InOSD,
        [Parameter()]
        [switch]
        $FailedOSD,
        [Parameter()]
        [switch]
        $SuccessfulOSD
    )


    # Function to install NuGet and the PSTeams module to simplify the notifcation card creation (no JSON, yay!)
    Function Install-PSTeamsModule {
        Write-Verbose 'NuGet is required. Pre-installing it (Running a Get prompt to install it, if missing).'
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Write-Verbose 'Grabbing the version of PSTeams from the gallery...'
        $PSTeamsGalleryModuleVersion = (Find-Module PSTeams).Version
        Write-Verbose 'Gallery version is:'
        Write-Verbose $PSTeamsGalleryModuleVersion
        Write-Verbose 'Grabbing the version of PSTeams that is installed (if any)...'
        $PSTeamsInstalledModuleVersion = (Get-InstalledModule PSTeams -ErrorAction SilentlyContinue).Version
        
        If ($PSTeamsGalleryModuleVersion -eq $PSTeamsInstalledModuleVersion) {
            Write-Verbose 'Installed version matches the gallery version; loading module.'
            Import-Module PSTeams
        }
        ElseIf ($null -ne $PSTeamsInstalledModuleVersion) {
            Write-Verbose 'Installed version is:'
            Write-Verbose $PSTeamsInstalledModuleVersion
            Write-Verbose 'Comparing the two to see if the gallery is newer...'
            If (!($PSTeamsInstalledModuleVersion -ge $PSTeamsGalleryModuleVersion)) {
                Write-Verbose 'Gallery version is newer; updating the PSTeams module and importing it.'
                Update-Module PSTeams -Force
                Import-Module PSTeams
            }
        }
        Else {
            Write-Verbose 'PSTeams is not installed; installing and importing the module.'
            Install-Module -Name PSTeams -Force
            Import-Module -Name PSTeams
        }
    }

    # Teams Incoming Webhook URL for testing
    # $webhookURL = 'https://contosocom.webhook.office.com/webhookb2/guid-here-ya-git'

    # Setup the TSEnv, if InOSD specified
    If ($inOSD) {
        $tsEnv = New-Object -ComObject Microsoft.SMS.TSEnvironement -ErrorAction SilentlyContinue
    }

    # Date/Time
    $dateTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"

    # Populate ComputerSystem and BIOS Data
    $compSys = Get-WmiObject -Class Win32_ComputerSystem
    $Bios = Get-WmiObject -Class Win32_BIOS

    # Computer Name
    If ($inOSD) {
        If ($tsEnv.Value("_SMSTSPackageName") -ne "") {
            $Name = $tsEnv.Value("_SMSTSMachineName")
        }
        Else {
            $Name = $compSys.Name
        }
    }
    Else {
        $Name = $compSys.Name
    }

    # Computer Make
    $Make = $compSys.Manufacturer

    # Computer Model
    $Model = $compSys.Model

    # Computer Baseboard Product Code
    $Baseboard = (Get-WmiObject -Class Win32_Baseboard).Product

    # Computer Serial Number
    [string]$Serial = $Bios.SerialNumber

    # Computer IP Address
    $ipAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -notlike $null}).IPAddress | Select-Object -First 1

    # Task Sequence Name if $inOSD
    If ($inOSD) {
        If ($tsEnv.Value("_SMSTSPackageName") -ne "") {
            $tsName = $tsEnv.Value("_SMSTSPackageName")
        }
        Else {
            $tsName = "Unknown Task Sequence"
        }
    }

    # Log location if $inOSD and $FailedOSD
    $failedLogs = "\\memcm.contoso.com\TSSD\OSD\TS_FailLogs\$Name"

    # Populate the Error Return Code and Task Name if $inOSD and $FailedOSD
    If ($inOSD -And $FailedOSD) {
        Try {
            $tsLastErrorCode = ($tsEnv.Value("_SMSTSLastActionRetCode"))
            If ([string]::IsNullOrEmpty($tsLastErrorCode)) {
                $tsLastErrorCode = "Unknown Error. Please consult the logs."
            }
            $tsFailedTaskName = $tsEnv.Value('_SMSLastActionName')
            $tsenv.Value('CNT_FailedTaskName') = $tsenv.Value('_SMSTSLastActionName') # Used in existing "Throw Error Dialog" step; adding back in to maintain functionality
        }
        Catch {
            Write-Host "Error pulling task sequence values. Exception: $($_.Exception.Message)"
        }
    }

    # Send the card if successful, or send it with different parameters if erred
    If ($InOSD -And $SuccessfulOSD) {
        New-AdaptiveCard -Uri $WebhookURL {
            New-AdaptiveTextBlock -Text "$Name imaged successfully!" -Weight Bolder -Size ExtraLarge -Color Good
            New-AdaptiveColumnSet {
                New-AdaptiveColumn -Width auto {
                    New-AdaptiveImage -Url "https://static-s.aa-cdn.net/img/gp/20600001711818/unUtqpVgwh3J6h_C4wmb0_Zc4ZuESSFejC9eJ8APpa8qy7EV1ulb1x9NufuSuBwm8A=w300" -Size Small -Style person
                }
                New-AdaptiveColumn -Width stretch {
                    New-AdaptiveTextBlock -Text "Please validate machine configuration, and deploy." -Weight Bolder -Wrap
                    New-AdaptiveTextBlock -Text "OSD completed: $dateTime" -Subtle -Spacing None -Wrap
                }
            }
            New-AdaptiveTextBlock -Text "Machine details:" -Wrap
            New-AdaptiveFactSet {
                New-AdaptiveFact -Title 'Computer Name:' -Value $Name
                New-AdaptiveFact -Title 'Manufacturer:' -Value $Make
                New-AdaptiveFact -Title 'Model:' -Value $Model
                New-AdaptiveFact -Title 'Serial:' -Value $Serial
                New-AdaptiveFact -Title 'Baseboard Model:' -Value $BaseBoard
                New-AdaptiveFact -Title 'IP:' -Value $ipAddress
                New-AdaptiveFact -Title 'Task Sequence:' -Value $tsName
            }
        } <# -Action {
            New-AdaptiveAction -Title 'Intune (Test)' -ActionUrl "https://endpoint.microsoft.com"
        } #>
    }
    ElseIf ($inOSD -And $FailedOSD) {
        New-AdaptiveCard -Uri $WebhookURL {
            New-AdaptiveTextBlock -Text "$Name failed to image properly." -Weight Bolder -Size ExtraLarge -Color Attention
            New-AdaptiveColumnSet {
                New-AdaptiveColumn -Width auto {
                    New-AdaptiveImage -Url "https://static-s.aa-cdn.net/img/gp/20600001711818/unUtqpVgwh3J6h_C4wmb0_Zc4ZuESSFejC9eJ8APpa8qy7EV1ulb1x9NufuSuBwm8A=w300" -Size Small -Style person
                }
                New-AdaptiveColumn -Width stretch {
                    New-AdaptiveTextBlock -Text "Error code: $tsLastErrorCode" -Weight Bolder -Wrap
                    New-AdaptiveTextBlock -Text "OSD failed: $dateTime" -Subtle -Spacing None -Wrap
                }
            }
            New-AdaptiveTextBlock -Text "Machine details:" -Wrap
            New-AdaptiveFactSet {
                New-AdaptiveFact -Title 'Erred Step:' -Value $tsFailedTaskName
                New-AdaptiveFact -TItle 'Error Code:' -Value $tsLastErrorCode
                New-AdaptiveFact -Title 'Log Location:' -Value $failedLogs
                New-AdaptiveFact -Title 'Computer Name:' -Value $Name
                New-AdaptiveFact -Title 'Manufacturer:' -Value $Make
                New-AdaptiveFact -Title 'Model:' -Value $Model
                New-AdaptiveFact -Title 'Serial:' -Value $Serial
                New-AdaptiveFact -Title 'Baseboard Model:' -Value $BaseBoard
                New-AdaptiveFact -Title 'IP:' -Value $ipAddress
                New-AdaptiveFact -Title 'Task Sequence:' -Value $tsName
            }
        } <# -Action {
            New-AdaptiveAction -Title 'Intune (Test)' -ActionUrl "https://endpoint.microsoft.com"
        } #>
    }
    Else {
        New-AdaptiveCard -Uri $WebhookURL {
            New-AdaptiveTextBlock -Text 'Teams Test Notification' -Weight Bolder -Size ExtraLarge -Color Good
            New-AdaptiveColumnSet {
                New-AdaptiveColumn -Width auto {
                    New-AdaptiveImage -Url "https://static-s.aa-cdn.net/img/gp/20600001711818/unUtqpVgwh3J6h_C4wmb0_Zc4ZuESSFejC9eJ8APpa8qy7EV1ulb1x9NufuSuBwm8A=w300" -Size Small -Style person
                }
                New-AdaptiveColumn -Width stretch {
                    New-AdaptiveTextBlock -Text "$Name successfully imaged." -Weight Bolder -Wrap
                    New-AdaptiveTextBlock -Text "OSD completed: $dateTime" -Subtle -Spacing None -Wrap
                }
            }
            New-AdaptiveTextBlock -Text "Machine details:" -Wrap
            New-AdaptiveFactSet {
                New-AdaptiveFact -Title 'Computer Name:' -Value $Name
                New-AdaptiveFact -Title 'Manufacturer:' -Value $Make
                New-AdaptiveFact -Title 'Model:' -Value $Model
                New-AdaptiveFact -Title 'Serial:' -Value $Serial
                New-AdaptiveFact -Title 'Baseboard Model:' -Value $BaseBoard
                New-AdaptiveFact -Title 'IP:' -Value $ipAddress
            }
        } <# -Action {
            New-AdaptiveAction -Title 'Intune (Test)' -ActionUrl "https://endpoint.microsoft.com"
        } #>
    }
}