# Grab the machine type
$osdType = Get-ItemPropertyValue -Path 'HKLM:\Software\CompanyName' -Name 'SMSOSD-Type'

# Grab the serial number
$serial = Get-CimInstance Win32_BIOS | Select-Object SerialNumber

# Assemble the two into the initial ComputerName
$initialName = $osdType + '-' + $serial.SerialNumber

# Check if the length of the string is greater than the 15 character computer name limit
If ($initialName.Length -gt 15) {
    # Truncate that value to no more than 15 characters by cutting the end off
    # The '0' indicates the starting point, and the '15' indicates how many characters we want to include
    $computerName = $initialName.substring(0,15)    
}
Else {
    # If it is 15 or less, just set the computer name
    $computerName = $initialName
}

# Set the possible prefixes
$prefixes = 'STD','KSK','LPTP'

# Loop through the prefixes, build the names, nuke anything found
ForEach ($prefix in $prefixes) {
    # Assemble the prefix and serial into the initial PrefixName
    $prefixName = $prefix + '-' + $serial.SerialNumber
    # Check if the length of the string is greater than the 15 character computer name limit
    If ($prefixName.Length -gt 15) {
        # Truncate that value to no more than 15 characters by cutting the end off
        # The '0' indicates the starting point, and the '15' indicates how many characters we want to include
        $validateName = $prefixName.substring(0,15)    
    }
    Else {
        # If it is 15 or less, just set the computer name
        $validateName = $prefixName
    }
    # When running AutoPilot in a Hybrid scenario, every time the AP is run it generates a new computer object
    # Check if a computer by the specific name alreadys exists and blow it away if it does
    $strDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $strRoot = $strDomain.GetDirectoryEntry()
    $objSearcher = [System.DirectoryServices.DirectorySearcher]$strRoot

    # Find AD computer object.
    $objSearcher.Filter = "(sAMAccountName=$validateName`$)"
    $objSearcher.PropertiesToLoad.Add("distinguishedName") > $Null

    $colResults = $objSearcher.FindAll()
    ForEach ($strComputer In $colResults) {
        $strDN = $strComputer.properties.Item("distinguishedName")
        $Computer = [ADSI]"LDAP://$strDN"
        # NUKE IT
        $Computer.DeleteTree()
    }
}

# Now, rename the current PC
(Get-WmiObject Win32_ComputerSystem).Rename($computerName)