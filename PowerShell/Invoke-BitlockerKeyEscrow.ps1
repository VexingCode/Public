<#
.SYNOPSIS
    Escrow an existing Bitlocker key protector to Azure AD (and Intune)
.DESCRIPTION
    The script validates that the $env:SystemDrive is protected by Bitlocker. It then backs the
    key up to Azure AD utilizing BackupToAAD-BitlockerKeyProtector. Lastly, it queries the Event
    Logs for an event in the past 5 minutes, ensuring that it was successful.
.EXAMPLE
    PS C:\> Invoke-BitlockerKeyEscrow
.INPUTS
    None
.OUTPUTS
    Successful output (drive Bitlockered)
        PS C:\> Invoke-BitlockerKeyEscrow
        Key escrow cmdlet run successfully.
        Event log shows the key was successfully backed up to Azure AD on 11/04/2022 09:09:55.

    Successful output (drive not Bitlockered)
        PS C:\> Invoke-BitlockerKeyEscrow
        Bitlocker was not found protecting the $BLD drive. Exiting script.

    Unsuccessful output
        PS C:\> Invoke-BitlockerKeyEscrow
        Something went wrong. Please consult C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log, and the event viewer.
.NOTES
    Name:           Invoke-BitlockerKeyEscrow.ps1
    Author:         Ahnamataeus Vex
    Credit:         Michael Mardahl
                        Script        : https://github.com/mardahl/PSBucket/blob/master/Invoke-EscrowBitlockerToAAD.ps1
                        Twitter       : @michael_mardahl
                        Blogging on   : www.msendpointmgr.com
                        Creation Date : 11 January 2021
                        Purpose/Change: Initial script
                        License       : MIT (Leave author credits)
    Version:        1.0.0
    Release Date:   2022-11-04
#>


Function Invoke-BitlockerKeyEscrow {

    # Set the drive letter:
    $BLD = $env:SystemDrive

    # Get the Bitlocker volume
    Try {
        $BLV = Get-BitLockerVolume -MountPoint $BLD -ErrorAction Stop
    }
    Catch {
        Write-Output "Bitlocker was not found protecting the $BLD drive. Exiting script."
        exit 0
    }

    # Backup the Bitlocker Key Protector to Azure AD
    Try {
        BackupToAAD-BitLockerKeyProtector -MountPoint $BLD -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId | Out-Null
        Write-Output "Key escrow cmdlet run successfully."
    }
    Catch {
        Write-Output "Something went wrong. Please consult C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log, and the event viewer."
        exit 1
    }

    # Wait 5 seconds for the event log to generate
    Start-Sleep -Seconds 5

    # Validate that the event log shows the key was backed up successfully, in the past 5 minutes
    $BLMessage = "BitLocker Drive Encryption recovery information for volume $BLD was backed up successfully to your Azure AD."
    If (Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-BitLocker/BitLocker Management'; Id='845'} -MaxEvents 1 | Where-Object { $_.Message -match $BLMessage -and $_.TimeCreated -gt [datetime]::Now.AddMinutes(-5) }) {
        $BLEventTime = (Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-BitLocker/BitLocker Management'; Id='845'} -MaxEvents 1 | Where-Object { $_.Message -match $BLMessage -and $_.TimeCreated -gt [datetime]::Now.AddMinutes(-5) }).TimeCreated
        Write-Output "Event log shows the key was successfully backed up to Azure AD on $BLEventTime." 
        exit 0
    }
    Else {
        Write-Output "There is no event log in the past 5 minutes showing the key was successfully exported to Azure AD. Please troubleshoot."
        exit 1
    }
}