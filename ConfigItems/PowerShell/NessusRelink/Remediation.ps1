# Remediation

# Write the variables
$RegKey = 'HKLM:\SOFTWARE\Contoso'
$nessusProperty = 'Nessus-Relink'
$nessusPropertyValue = '1'
$nessusRelinkErrorProp = 'Nessus-Relink-Error'
$nessusUnlinkErrorProp = 'Nessus-Unlink-Error'
$nessusAgent = 'C:\Program Files\Tenable\Nessus Agent\nessuscli.exe'

# Test if the NessusCLI.exe even exists
If (Test-Path $nessusAgent -ErrorAction SilentlyContinue) {
    # Test if the $RegKey\Nessus registry key exists
    If (!(Test-Path $RegKey\Nessus -ErrorAction SilentlyContinue)) {
        # Registry key does not exist; creating it
        New-Item -Path $RegKey\Nessus -Force | Out-Null

        # Unlink and relink Nessus
        $unlink = & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent unlink
        $relink = & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent link --groups="Desktops" --cloud --key=KEY-HERE

        # Write the key showing its been run
        New-ItemProperty $RegKey\Nessus -Name $nessusProperty -PropertyType String -Value $nessusPropertyValue -Force | Out-Null
        Write-Output "Nessus agent relinked."
        exit 0
    } Else {
        # Validate that the Nessus property actually exists with Get-ItemProperty; Get-ItemPropertyValue throws an irrepressible error
        If (Get-ItemProperty $RegKey\Nessus -Name $nessusProperty -ErrorAction SilentlyContinue) {
            # Nessus registry key exists; validate if its the same value as the script
            If ((Get-ItemPropertyValue $RegKey\Nessus -Name $nessusProperty) -eq $nessusPropertyValue) {
                # The values match; the commands have been run already

                # Remove the error keys if present
                If (Get-ItemProperty $RegKey\Nessus -Name $nessusUnlinkErrorProp -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty $RegKey\Nesus -Name $nessusUnlinkErrorProp -Force -ErrorAction SilentlyContinue | Out-Null
                }
                If (Get-ItemProperty $RegKey\Nessus -Name $nessusRelinkErrorProp -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty $RegKey\Nesus -Name $nessusRelinkErrorProp -Force -ErrorAction SilentlyContinue | Out-Null
                }

                Write-Output "The Nessus agent relink was already run."
                exit 0
            } Else {
                # The values do not match; remove the error keys if present
                If (Get-ItemProperty $RegKey\Nessus -Name $nessusUnlinkErrorProp -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty $RegKey\Nesus -Name $nessusUnlinkErrorProp -Force -ErrorAction SilentlyContinue | Out-Null
                }
                If (Get-ItemProperty $RegKey\Nessus -Name $nessusRelinkErrorProp -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty $RegKey\Nesus -Name $nessusRelinkErrorProp -Force -ErrorAction SilentlyContinue | Out-Null
                }

                # Unlink and relink Nessus
                $unlink = & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent unlink
                $relink = & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent link --groups="Desktops" --cloud --key=KEY-HERE
                
                # Set the key to the new value
                Set-ItemProperty $RegKey\Nessus -Name $nessusProperty -Value $nessusPropertyValue -Force | Out-Null
                Write-Output "Nessus agent relinked."
                exit 0
            }
        } Else {
            # The Nessus path exists, but not the key; assume it has not been relinked
            # Unlink and relink Nessus
            $unlink = & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent unlink
            $relink = & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent link --groups="Desktops" --cloud --key=KEY-HERE
            
            # Write the key showing its been run
            New-ItemProperty $RegKey\Nessus -Name $nessusProperty -PropertyType String -Value $nessusPropertyValue -Force | Out-Null
            Write-Output "Nessus agent relinked."
            # exit 0
        }
    }
} Else {
    # NessusCLI.exe not found
    Write-Output 'NessusCLI.exe does not exist. Throwing error 1.'
    exit 1
}