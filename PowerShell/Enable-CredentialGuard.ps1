<#
.SYNOPSIS
    Enable Credential Guard on Windows 10

.DESCRIPTION
    This script will enable a Windows 10 device to leverage Credential Guard in order to prevent pass-the-hash attacks.

.EXAMPLE
    .\Enable-CredentialGuard.ps1

.NOTES

    Version history:
    1.0.0 - (2016-06-08) Script created
    1.0.1 - (2016-08-10) Script updated to support Windows 10 version 1607 that no longer required the Isolated User Mode feature, since it's embedded in the hypervisor
    1.0.2 - (2017-07-03) Script updated since Windows 10 version 1607 and higher no longer needs Hyper-V feature for enabling Credential Guard
    1.0.3 - (2021-09-16) Script updated to remove the CM OSD sections; original script saved as 'Enable-CredentialGuardInOSD.ps1'

.NOTES
    FileName:    Enable-CredentialGuard.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Contributer: Ahnamataeus Vex
    Created:     2016-06-08
    Updated:     2021-09-16
    Version:     1.0.3
#>
# Functions
Function Write-CGLogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value added to the log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("1", "2", "3")]
        [string]$Severity,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "EnableCredentialGuard.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path 'C:\Windows\Logs' -ChildPath $FileName

    # Construct time stamp for log entry
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

    # Construct date for log entry
    $Date = (Get-Date -Format "MM-dd-yyyy")

    # Construct context for log entry
    $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

    # Construct final log entry
    $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""CredentialGuard"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"

    # Add value to log file
    try {
        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to EnableCredentialGuard.log file"
    }
}

# Write beginning of log file
Write-CGLogEntry -Value "Starting configuration for Credential Guard" -Severity 1

if ([int](Get-WmiObject -Class Win32_OperatingSystem).BuildNumber -lt 14393) {
    try {
        # For version older than Windows 10 version 1607 (build 14939), enable required Windows Features for Credential Guard
        Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-HyperVisor -Online -All -LimitAccess -NoRestart -ErrorAction Stop
        Write-CGLogEntry -Value "Successfully enabled Microsoft-Hyper-V-HyperVisor feature" -Severity 1

        # For version older than Windows 10 version 1607 (build 14939), add the IsolatedUserMode feature as well
        Enable-WindowsOptionalFeature -FeatureName IsolatedUserMode -Online -All -LimitAccess -NoRestart -ErrorAction Stop
        Write-CGLogEntry -Value "Successfully enabled IsolatedUserMode feature" -Severity 1
    }
    catch [System.Exception] {
        Write-CGLogEntry -Value "An error occured when enabling required windows features" -Severity 3
    }
}

# Add required registry key for Credential Guard
$RegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
If (-not(Test-Path -Path $RegistryKeyPath)) {
    Write-CGLogEntry -Value "Creating HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard registry key" -Severity 1
    New-Item -Path $RegistryKeyPath -ItemType Directory -Force
}

# Add registry value RequirePlatformSecurityFeatures - 1 for Secure Boot only, 3 for Secure Boot and DMA Protection
Write-CGLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\RequirePlatformSecurityFeatures value as DWORD with data 1" -Severity 1
New-ItemProperty -Path $RegistryKeyPath -Name RequirePlatformSecurityFeatures -PropertyType DWORD -Value 1

# Add registry value EnableVirtualizationBasedSecurity - 1 for Enabled, 0 for Disabled
Write-CGLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\EnableVirtualizationBasedSecurity value as DWORD with data 1" -Severity 1
New-ItemProperty -Path $RegistryKeyPath -Name EnableVirtualizationBasedSecurity -PropertyType DWORD -Value 1

# Add registry value LsaCfgFlags - 1 enables Credential Guard with UEFI lock, 2 enables Credential Guard without lock, 0 for Disabled
Write-CGLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\LsaCfgFlags value as DWORD with data 1" -Severity 1
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name LsaCfgFlags -PropertyType DWORD -Value 1

# Write end of log file
Write-CGLogEntry -Value "Successfully enabled Credential Guard" -Severity 1