<#
.SYNOPSIS
    Wipe and re-trigger ConfigMgr client inventories.
.DESCRIPTION
    "First, it cleans out all of the previous inventory, so it forces the ConfigMgr client to perform a full inventory. 
    Next, it triggers each of the inventory items from fastest to slowest. This means that Heartbeat Discovery (aka the
    Discovery Data Collection cycle on the ConfigMgr client computer) and hardware inventory get returned within a few
    minutes, and the remaining software inventory ones, take hours, if not days, to return."
.EXAMPLE
    PS C:\> Reset-CMInventory
    When the -Comptuer parameter is not specified, it wipes and re-triggers the syncs on the local machine.

    PS C:\> Reset-CMInventory -Computer 'hostname'
    When the -Computer parameter is specified, it wipes and re-triggers the syncs on that machine.
.INPUTS
    -Computer
        This parameter specifies a computer to target. If not specified at all, it will default to $env:COMPUTERNAME
.OUTPUTS
    None.
.NOTES
    Name:      Reset-CMInventory.ps1
    Author:    Ahnamataeus Vex
    Version: 1.0.0
    Release Date: 2021-12-07
    Notes: 
        Based off Garth Jones' script located here: 
            https://www.recastsoftware.com/resources/my-two-favorite-configmgr-run-scripts/
#>

Function Reset-CMInventory {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Computer
    )

    # If the parameter is not specified, then set it to the local machine
    If ($null -eq $Computer) {
        $Computer = $env:COMPUTERNAME
    }

    # Set the ID variables
    $HardwareInventoryID = '{00000000-0000-0000-0000-000000000001}'
    $SoftwareInventoryID = '{00000000-0000-0000-0000-000000000002}'
    $HeartbeatID = '{00000000-0000-0000-0000-000000000003}'
    $FileCollectionInventoryID = '{00000000-0000-0000-0000-000000000010}'

    # Wipe out the current WMI inventory ID entries
    Get-WmiObject -ComputerName $Computer -Namespace 'Root\CCM\INVAGT' -Class 'InventoryActionStatus' -Filter "InventoryActionID='$HardwareInventoryID'" | Remove-WmiObject
    Get-WmiObject -ComputerName $Computer -Namespace 'Root\CCM\INVAGT' -Class 'InventoryActionStatus' -Filter "InventoryActionID='$SoftwareInventoryID'" | Remove-WmiObject
    Get-WmiObject -ComputerName $Computer -Namespace 'Root\CCM\INVAGT' -Class 'InventoryActionStatus' -Filter "InventoryActionID='$HeartbeatID'" | Remove-WmiObject
    Get-WmiObject -ComputerName $Computer -Namespace 'Root\CCM\INVAGT' -Class 'InventoryActionStatus' -Filter "InventoryActionID='$FileCollectionInventoryID'" | Remove-WmiObject

    # Sleep for 5 seconds
    Start-Sleep -s 5

    # Invoke the WMI to run the syncs again
    Invoke-WmiMethod -computername $Computer -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList $HeartbeatID
    Invoke-WmiMethod -computername $Computer -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList $HardwareInventoryID
    Invoke-WmiMethod -computername $Computer -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList $SoftwareInventoryID
    Invoke-WmiMethod -computername $Computer -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList $FileCollectionInventoryID

}