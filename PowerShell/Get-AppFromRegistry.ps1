<#
.SYNOPSIS
    Searches the Uninstall registries for software of a specific version.
.DESCRIPTION
    This function searches both the 64 and 32bit Uninstall registry keys for a product with the specified name
    and "Greater Than or Equal To" the Version number specified. This is a quick function built to use as a
    Detection Method for ConfigMgr (hence the blank) and Intune (exit codes)
.EXAMPLE
    PS C:\> Get-AppFromRegistry -Name "Microsoft Edge" -Version 96.0.1054.57
    This searches for Microsoft Edge, version 90.0.1054.57 or above, and returns output if found or not.

    PS C:\> Get-AppFromRegistry -Name "Microsoft Edge" -Version 96.0.1054.57 -ConfigMgr
    This searches for Microsoft Edge, version 90.0.1054.57 or above, and returns $true if found, or nothing if not.

    PS C:\> Get-AppFromRegistry -Name "Microsoft Edge" -Version 96.0.1054.57 -Intune
    This searches for Microsoft Edge, version 90.0.1054.57 or above, and returns an output with Exit 0 if found, or an output with Exit 1 if not.
.INPUTS
    -Name
        This parameter specifies the exact name of the product you are looking for.

    -Version
        This parameter specifies the version number, or greater, you are looking for.

    -ConfigMgr
        This parameter specifies that you want the output to be compliant for a ConfigMgr detection method.

    -Intune
        This parameter specifies that you want the output to be compliant for an Intune detection method.
.OUTPUTS
    Compliance or not.
.NOTES
    Name:         Get-AppFromRegistry.ps1
    Author:       Ahnamataeus Vex
    Version:      1.0.0
    Release Date: 2021-12-17
#>

Function Get-AppFromRegistry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        [Parameter(Mandatory=$true)]
        [string]
        $Version,
        [Parameter(Mandatory=$false)]
        [switch] $ConfigMgr,
        [Parameter(Mandatory=$false)]
        [switch] $Intune
    )

    $app64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq $Name} | Select-Object DisplayName,DisplayVersion
    $app32 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq $Name} | Select-Object DisplayName,DisplayVersion

    # Check if $app64 is null; E.g. the application was found
    If ($null -ne $app64) {
        # Make sure the name matches and the version is -ge to $version
        If ( (($app64).DisplayName -eq $Name) -and (($app64).DisplayVersion -ge $Version) ) {
            # ConfigMgr switch specified
            If ($ConfigMgr) {
                # Return true for ConfigMgr Detection Method
                $True
            }
            # Intune switch specified
            ElseIf ($Intune) {
                # Return Output and Exit 0 for Intune Detection Method
                Write-Output "$Name was found under Uninstall key, and the version was greater than or equal to $Version."
                Exit 0
            }
            # No switch specified
            Else {
                # Return Output
                Write-Output "$Name was found under Uninstall key, and the version was greater than or equal to $Version."
            }
        }
        Else {
            If ($ConfigMgr) {
                # Return nothing for ConfigMgr Detection Method, indicating it is not installed
            }
            # Intune switch specified
            ElseIf ($Intune) {
                # Return Output and Exit 1 for Intune Detection Method
                Write-Output "$Name was not found under Uninstall key, but the version is not greater than or equal to $Version."
                Exit 1
            }
            # No switch specified
            Else {
                # Return Output
                Write-Output "$Name was not found under Uninstall key, but the version is not greater than or equal to $Version."
            }
        }
    }
    ElseIf ($null -ne $app32) {
        # Make sure the name matches and the version is -ge to $version
        If ( (($app32).DisplayName -eq $Name) -and (($app32).DisplayVersion -ge $Version) ) {
            # ConfigMgr switch specified
            If ($ConfigMgr) {
                # Return true for ConfigMgr Detection Method
                $True
            }
            # Intune switch specified
            ElseIf ($Intune) {
                # Return Output and Exit 0 for Intune Detection Method
                Write-Output "$Name was found under Wow6432Node Uninstall key, and the version was greater than or equal to $Version."
                Exit 0
            }
            # No switch specified
            Else {
                # Return Output
                Write-Output "$Name was found under Wow6432Node Uninstall key, and the version was greater than or equal to $Version."
            }
        }
        Else {
            If ($ConfigMgr) {
                # Return nothing for ConfigMgr Detection Method, indicating it is not installed
            }
            # Intune switch specified
            ElseIf ($Intune) {
                # Return Output and Exit 1 for Intune Detection Method
                Write-Output "$Name was not found under Wow6432Node Uninstall key, but the version is not greater than or equal to $Version."
                Exit 1
            }
            # No switch specified
            Else {
                # Return Output
                Write-Output "$Name was not found under Wow6432Node Uninstall key, but the version is not greater than or equal to $Version."
            }
        }
    }
    Else {
        If ($ConfigMgr) {
            # Return nothing for ConfigMgr Detection Method, indicating it is not installed
        }
        # Intune switch specified
        ElseIf ($Intune) {
            # Return Output and Exit 1 for Intune Detection Method
            Write-Output "$Name was not found under either Uninstall key."
            Exit 1
        }
        # No switch specified
        Else {
            # Return Output
            Write-Output "$Name was not found under either Uninstall key."
        }
    }
}