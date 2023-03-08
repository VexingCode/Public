Function Get-WindowsFoD {

    <#
    .SYNOPSIS
        Searches the PackageIndex registries for validated FoDs.
    .DESCRIPTION
        This function searches the PackageIndex registry keys for a matching registry key, based on the validated
        name from the -FeatureName parameter. This function can be run without Administrative permissions, whereas
        Get-WindowsCapability cannot. When deploying applications, in ConfigMgr, to users the detection script is
        run under their permissions. Without Admin, Get-WindowsCapability returns as "Not Applicable."
        
        This is a quick function built to use as a Detection Method for ConfigMgr (hence the blank) and Intune (exit codes).
    .EXAMPLE
        PS C:\> Get-WindowsFoD -FeatureName 'Active Directory Tools'
        This searches for Active Directory Tools and returns output if found or not.

        PS C:\> Get-WindowsFoD -FeatureName 'Active Directory Tools' -ConfigMgr
        This searches for Active Directory Tools and returns $true if found, or nothing if not.

        PS C:\> Get-WindowsFoD -FeatureName 'Active Directory Tools' -Intune
        This searches for Active Directory Tools and returns an output with Exit 0 if found, or an output with Exit 1 if not.
    .INPUTS
        -FeatureName
        This parameter specifies the exact name of the FoD you are looking for. It is a validated set, meaning it must
        be one of the below values. You can tab-complete and tab-cycle through this list after specifying the parameter.
        It is not case sensitive.
            'Active Directory Tools'
            'BitLocker Recovery Tools'
            'Certificate Services Tools'
            'DHCP Tools'
            'DNS Tools'
            'Failover Cluster Management Tools'
            'File Services Tools'
            'Group Policy Management Tools'
            'IPAM Client Tools'
            'LLDP Tools'
            'Network Controller Tools'
            'Network Load Balancing Tools'
            'Remote Access Management Tools'
            'Remote Desktop Services Tools'
            'Server Manager Tools'
            'Shielded VM Tools'
            'Storage Migration Service Management Tools'
            'Storage Replica Tools'
            'System Insights Management Tools'
            'Volume Activation Tools'
            'WSUS Tools'

        -ConfigMgr
            This parameter specifies that you want the output to be compliant for a ConfigMgr detection method.

        -Intune
            This parameter specifies that you want the output to be compliant for an Intune detection method.
    .OUTPUTS
        Compliance or not.
    .NOTES
        Name:         Get-WindowsFoD.ps1
        Author:       Ahnmataeus Vex
        Version:      1.0.0
        Release Date: 2021-12-20
    #> 

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Active Directory Tools', 'BitLocker Recovery Tools', 'Certificate Services Tools', 'DHCP Tools', 'DNS Tools', 'Failover Cluster Management Tools', 'File Services Tools', 'Group Policy Management Tools','IPAM Client Tools','LLDP Tools','Network Controller Tools','Network Load Balancing Tools','Remote Access Management Tools','Remote Desktop Services Tools','Server Manager Tools','Shielded VM Tools','Storage Migration Service Management Tools','Storage Replica Tools','System Insights Management Tools','Volume Activation Tools','WSUS Tools')]
        [string] $FeatureName,
        [Parameter(Mandatory=$false)]
        [switch] $ConfigMgr,
        [Parameter(Mandatory=$false)]
        [switch] $Intune
    )

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackageIndex"

    $FoDs = @{
        "Active Directory Tools"    = @{
            RegistryKey = "Microsoft-Windows-ActiveDirectory-DS-LDS-Tools-FoD*"
            DISMName    = "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"     
        }
        "BitLocker Recovery Tools"  = @{
            RegistryKey = "Microsoft-Windows-BitLocker-Recovery-Tools-FoD*"
            DISMName    = "Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0"
        }
        "Certificate Services Tools"  = @{
            RegistryKey = "Microsoft-Windows-CertificateServices-Tools-FoD*"
            DISMName    = "Rsat.CertificateServices.Tools~~~~0.0.1.0"
        }
        "DHCP Tools"  = @{
            RegistryKey = "Microsoft-Windows-DHCP-Tools-FoD*"
            DISMName    = "Rsat.DHCP.Tools~~~~0.0.1.0"
        }
        "DNS Tools"  = @{
            RegistryKey = "Microsoft-Windows-DNS-Tools-FoD*"
            DISMName    = "Rsat.DHCP.Tools~~~~0.0.1.0"
        }
        "Failover Cluster Management Tools"  = @{
            RegistryKey = "Microsoft-Windows-FailoverCluster-Management-Tools-FOD*"
            DISMName    = "Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0"
        }
        "File Services Tools"  = @{
            RegistryKey = "Microsoft-Windows-FileServices-Tools-FoD*"
            DISMName    = "Rsat.FileServices.Tools~~~~0.0.1.0"
        }
        "Group Policy Management Tools"  = @{
            RegistryKey = "Microsoft-Windows-GroupPolicy-Management-Tools-FoD*"
            DISMName    = "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
        }
        "IPAM Client Tools"  = @{
            RegistryKey = "Microsoft-Windows-IPAM-Client-FoD*"
            DISMName    = "Rsat.IPAM.Client.Tools~~~~0.0.1.0"
        }
        "LLDP Tools"  = @{
            RegistryKey = "Microsoft-Windows-LLDP-Tools-FoD*"
            DISMName    = "Rsat.LLDP.Tools~~~~0.0.1.0"
        }
        "Network Controller Tools"  = @{
            RegistryKey = "Microsoft-Windows-NetworkController-Tools-FoD*"
            DISMName    = "Rsat.NetworkController.Tools~~~~0.0.1.0"
        }
        "Network Load Balancing Tools"  = @{
            RegistryKey = "Microsoft-Windows-NetworkLoadBalancing-Tools-FoD*"
            DISMName    = "Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0"
        }
        "Remote Access Management Tools"  = @{
            RegistryKey = "Microsoft-Windows-RemoteAccess-Management-Tools-FoD*"
            DISMName    = "Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0"
        }
        "Remote Desktop Services Tools"  = @{
            RegistryKey = "Microsoft-Windows-RemoteDesktop-Services-Tools-FoD*"
            DISMName    = "Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0"
        }
        "Server Manager Tools"  = @{
            RegistryKey = "Microsoft-Windows-ServerManager-Tools-FoD*"
            DISMName    = "Rsat.ServerManager.Tools~~~~0.0.1.0"
        }
        "Shielded VM Tools"  = @{
            RegistryKey = "Microsoft-Windows-Shielded-VM-Tools-FoD*"
            DISMName    = "Rsat.Shielded.VM.Tools~~~~0.0.1.0"
        }
        "Storage Migration Service Management Tools"  = @{
            RegistryKey = "Microsoft-Windows-StorageMigrationService-Management-Tools-FOD*"
            DISMName    = "Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0"
        }
        "Storage Replica Tools"  = @{
            RegistryKey = "Microsoft-Windows-StorageReplica-Tools-FoD*"
            DISMName    = "Rsat.StorageReplica.Tools~~~~0.0.1.0"
        }
        "System Insights Management Tools"  = @{
            RegistryKey = "Microsoft-Windows-SystemInsights-Management-Tools-FOD*"
            DISMName    = "Rsat.SystemInsights.Management.Tools~~~~0.0.1.0"
        }
        "Volume Activation Tools"  = @{
            RegistryKey = "Microsoft-Windows-VolumeActivation-Tools-FoD*"
            DISMName    = "Rsat.VolumeActivation.Tools~~~~0.0.1.0"
        }
        "WSUS Tools"  = @{
            RegistryKey = "Microsoft-Windows-WSUS-Tools-FoD*"
            DISMName    = "Rsat.WSUS.Tools~~~~0.0.1.0"
        }
    }

    ForEach ($Feature in $FoDs.Keys) {

        If ($FeatureName -match $Feature) {
            $reg = $FoDs[$feature].RegistryKey
            $fullRegKey = "$regPath\$reg"
            # $dism = $FoDs[$feature].DISMName
            
            If (Get-ChildItem $fullRegKey) {
                If ($ConfigMgr) {
                    # Return true for ConfigMgr Detection Method
                    $True
                }
                # Intune switch specified
                ElseIf ($Intune) {
                    # Return Output and Exit 0 for Intune Detection Method
                    Write-Output "$FeatureName was found in the registry; installed."
                    Exit 0
                }
                # No switch specified
                Else {
                    # Return Output
                    Write-Output "$FeatureName was found in the registry; installed."
                }
            }
            Else {
                If ($ConfigMgr) {
                    # Return nothing for ConfigMgr Detection Method, indicating it is not installed
                }
                # Intune switch specified
                ElseIf ($Intune) {
                    # Return Output and Exit 1 for Intune Detection Method
                    Write-Output "$FeatureName was not found in the registry; not installed."
                    Exit 1
                }
                # No switch specified
                Else {
                    # Return Output
                    Write-Output "$FeatureName was not found in the registry; not installed."
                }
            }
        }
    }
}