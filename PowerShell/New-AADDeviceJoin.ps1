<#
.SYNOPSIS
    Adds a machine to an AAD tenant, and runs the task to sync.
.DESCRIPTION
    This script will set the registry keys for the specified Azure AD tenant, and kick off
    the Scheduled Task to sync the device in. Useful for those scenarios where you aren't
    syncing a test OU with Azure AD Connect.
.EXAMPLE
    C:\Windows\System32> New-AADDeviceJoin -TenantID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' -TenantName 'TenantName Here'
.NOTES
    Name:           New-AADJ.ps1
    Author:         Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2022-07-22
#>

Function New-AADDeviceJoin {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $TenantID,
        [Parameter()]
        [string]
        $TenantName
    )

    # Check for elevation; throw error if not
    If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
        Break
    }

    # Set the HKEY path
    $hkeyAAD = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD'
    
    # Create the registry key
    Write-Host 'Creating the regkey if it does not exist.'
    If (!(Test-Path $hkeyAAD -ErrorAction SilentlyContinue)) {
        New-Item $hkeyAAD -Force | Out-Null
    }

    # Set the item properties for TenantID and TenantName
    Write-Host "Creating the registry properties for TenantID and TenantName, with the supplied values."
    New-ItemProperty $hkeyAAD -Name TenantID -PropertyType Sting -Value $TenantID -Force | Out-Null
    New-ItemProperty $hkeyAAD -Name TenantID -PropertyType Sting -Value $TenantName -Force | Out-Null

    # Trigger the builtin Scheduled Task to join it to Azure AD
    Write-Host "Trigger the builtin Scheduled Task for Automatic Device Join."
    Get-ScheduledTask -TaskName 'Automatic-Device-Join' | Start-ScheduledTask

    # Wait 10 seconds
    Write-Host "Waiting 10 seconds for that to bake..."
    Start-Sleep 10
    Write-Host "DING!" -ForegroundColor Cyan

    # Grab the output from dsregcmd /status
    Write-Host "Validating status with dsregcmd /status."
    $dsregcmdStatus = dsregcmd /status
    # Check if it shows the device is AzureAD joined
    If ($dsregcmdStatus -match 'AzureAdJoined : YES') {
        Write-Host 'Device shows as Azure AD Joined.'
        # Check that the TenantID and TenantName match the supplied values
        If (($dsregcmdStatus -match "TenantId : $TenantID") -and ($dsregcmdStatus -match "TenantName : $TenantName")) {
            Write-Host "Device is Azure AD Joined, with TenantID `"$TenantID`" and TenantName `"$TenantName`"." -ForegroundColor Green
        }
        Else {
            # They do not match; the user needs to investigate why
            Write-Host "Device shows AzureAD Joined, but the TenantID and TenantName do not match. Please run dsregcmd /status to see the current values and investigate the inconsistency." -ForegroundColor Yellow
        }
    }
    Else {
        # It did not join; purposefully not using a Do..Until loop at this time
        Write-Host "The device is still not AzureAD Joined. Please wait a bit longer and check with dsregcmd /status." -ForegroundColor Red
    }
}