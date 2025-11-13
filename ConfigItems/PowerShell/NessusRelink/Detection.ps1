# Detection

# Set vars
$RegKey = 'HKLM:\SOFTWARE\Contoso'
$nessusProperty = 'Nessus-Relink'
$nessusPropertyValue = '1'
$nessusAgent = 'C:\Program Files\Tenable\Nessus Agent\nessuscli.exe'

# Test if the NessusCLI.exe even exists
If (Test-Path $nessusAgent) {
    # Agent exists; test if the $RegKey\Nessus registry key exists
    If (!(Test-Path $RegKey\Nessus -ErrorAction SilentlyContinue)) {
        # Registry key does not exist so we assume the agent has not been relinked yet; return $false
        return $false
    }
    Else {
        # Validate that the Nessus property actually exists with Get-ItemProperty; Get-ItemPropertyValue throws an irrepressible error
        If (Get-ItemProperty $RegKey\Nessus -Name $nessusProperty -ErrorAction SilentlyContinue) {
            # Nessus registry key exists; validate if its the same value as the script
            If ((Get-ItemPropertyValue $RegKey\Nessus -Name $nessusProperty) -eq $nessusPropertyValue) {
                # The values match; the agent has been relinked
                return $true
            }
            Else {
                # The values do not match so the agent needs to be relinked, we return $false
                return $false
            }
        }
        Else {
            # The Nessus path exists, but not the key; assume it has not been relinked and return $false
            return $false
        }
    }
} Else {
    # NessusCLI.exe does not exist; non-compliant
    return $false
}