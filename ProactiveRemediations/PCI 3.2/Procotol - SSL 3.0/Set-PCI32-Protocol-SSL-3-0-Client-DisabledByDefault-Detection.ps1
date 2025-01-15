Function Set-PCI32 {
    <#
    .SYNOPSIS
        Validate and check the Protocols, Ciphers, and CipherSuites for PCI 3.2 compliance.
    .DESCRIPTION
        Checks the specified Protocol, Cipher, or CipherSuites for PCI 3.2 compliance. Intended for use with ConfigMgr
        on a per Protocol/Cipher/CipherSuite basis for Configuration Item reporting and remediation.
    .INPUTS
        -Protocol
            This parameter specifies the protocol you would like to validate or remediate.
            Valid options are:
                Multi-Protocol Unified Hello - This will DISABLE Multi-Protocol Unified Hello if -Remediate is specified
                PCT 1.0 - This will DISABLE PCT 1.0 if -Remediate is specified
                SSL 2.0 - This will DISABLE SSL 2.0 if -Remediate is specified
                SSL 3.0 - This will DISABLE SSL 3.0 if -Remediate is specified
                TLS 1.0 - This will DISABLE TLS 1.0 if -Remediate is specified
                TLS 1.1 - This will DISABLE TLS 1.1 if -Remediate is specified
                TLS 1.2 - This will ENABLE TLS 1.2 if -Remediate is specified
        -SubProtocol
            This parameter specifies the protocol you would like to validate or remediate. Both of these
            need to be set for compliance.
            Valid options are:
                Client
                Server
        -ProtocolProperty
            This parameter specifies the property you would like to validate or remediate. Both of these
            need to be set for compliance.
            Valid options are:
                Enabled
                DisabledByDefault

            NOTE: This option does not exist for Ciphers or CipherSuites; Ciphers only use "Enabled", and CipherSuites
            use a PowerShell cmdlet.
        -Cipher
            This parameter specifies the Cipher you would like to validate or remediate.
            Valid options are:
                AES 128/128 - This will ENABLE AES 128/128 if -Remediate is specified
                AES 256/256 - This will ENABLE AES 256/256 if -Remediate is specified
                DES 56/56 - This will DISABLE DES 56/56 if -Remediate is specified
                NULL- This will DISABLE NULL if -Remediate is specified
                RC2 128/128 - This will DISABLE RC2 128/128 if -Remediate is specified
                RC2 40/128 - This will DISABLE RC2 40/128 if -Remediate is specified
                RC2 56/128 - This will DISABLE RC2 56/128 if -Remediate is specified
                RC4 128/128 - This will DISABLE RC4 128/128 if -Remediate is specified
                RC4 40/128 - This will DISABLE RC4 40/128 if -Remediate is specified
                RC4 56/128 - This will DISABLE RC4 56/128 if -Remediate is specified
                RC4 64/128 - This will DISABLE RC4 64/128 1.0 if -Remediate is specified
                Triple DES 168 - This will ENABLE Triple DES 168 if -Remediate is specified
        -CipherSuite
            This parameter specified the Cipher Suite you would like to validate or remediate.
            Valid options are:
                TLS_AES_256_GCM_SHA384 - This will DISABLE TLS_AES_256_GCM_SHA384 if -Remediate is specified
                TLS_AES_128_GCM_SHA256 - This will DISABLE TLS_AES_128_GCM_SHA256 if -Remediate is specified
                TLS_DHE_RSA_WITH_AES_256_GCM_SHA384 - This will DISABLE TLS_DHE_RSA_WITH_AES_256_GCM_SHA384 if -Remediate is specified
                TLS_DHE_RSA_WITH_AES_128_GCM_SHA256 - This will DISABLE TLS_DHE_RSA_WITH_AES_128_GCM_SHA256 if -Remediate is specified
                TLS_RSA_WITH_3DES_EDE_CBC_SHA - This will DISABLE TLS_RSA_WITH_3DES_EDE_CBC_SHA if -Remediate is specified
                TLS_PSK_WITH_AES_256_GCM_SHA384 - This will DISABLE TLS_PSK_WITH_AES_256_GCM_SHA384 if -Remediate is specified
                TLS_PSK_WITH_AES_128_GCM_SHA256 - This will DISABLE TLS_PSK_WITH_AES_128_GCM_SHA256 if -Remediate is specified
                TLS_PSK_WITH_AES_256_CBC_SHA384 - This will DISABLE TLS_PSK_WITH_AES_256_CBC_SHA384 if -Remediate is specified
                TLS_PSK_WITH_AES_128_CBC_SHA256 - This will DISABLE TLS_PSK_WITH_AES_128_CBC_SHA256 if -Remediate is specified
                TLS_PSK_WITH_NULL_SHA384 - This will DISABLE TLS_PSK_WITH_NULL_SHA384 if -Remediate is specified
                TLS_PSK_WITH_NULL_SHA256 - This will DISABLE TLS_PSK_WITH_NULL_SHA256 if -Remediate is specified
                TLS_RSA_WITH_NULL_SHA256 - This will DISABLE TLS_RSA_WITH_NULL_SHA256 if -Remediate is specified
                TLS_RSA_WITH_NULL_SHA - This will DISABLE TLS_RSA_WITH_NULL_SHA if -Remediate is specified
        -Toggle (UNUSED: CURRENTLY IN DEV)
            This parameter specifies whether to detect or remediate if the setting is enabled or 
            disabled.
            Valid options are:
                Enable
                Disable
        -Remediate
            This parameter is a swich that will tell the function to return $true or 
            $false (validate), or to remediate by creating/setting the values.
    .EXAMPLE
        Set-PCI32 -Protocol "TLS 1.0" -SubProtocol "Client" -Property "Enabled"

        This will check that the TLS 1.0\Client property "Enabled" exists, and ensure its set to 0.
        If not it will return $false.
    .EXAMPLE
        Set-PCI32 -Protocol "TLS 1.0" -SubProtocol "Client" -Property "Enabled" -Remediate

        This will check that the TLS 1.0\Client property "Enabled" exists, and ensure its set to 0.
        If not it will remediate it by ensuring the key, property, and value are all created and
        set.
    .EXAMPLE
        Set-PCI32 -Protocol "TLS 1.0" -SubProtocol "Server" -Property "DisabledByDefault"

        This will check that the TLS 1.0\Server property "DisabledByDefault" exists, and ensure its set to 0.
        If not it will return $false.
    .EXAMPLE
        Set-PCI32 -Protocol "TLS 1.0" -SubProtocol "Server" -Property "DisabledByDefault" -Remediate

        This will check that the TLS 1.0\Server property "DisabledByDefault" exists, and ensure its set to 0.
        If not it will remediate it by ensuring the key, property, and value are all created and
        set.
    .EXAMPLE
        Set-PCI32 -Cipher "NULL"

        This will check that the Cipher\NULL property "Enabled" exists, and ensure its set to 0.
        If not it will return $false.
    .EXAMPLE
        Set-PCI32 -Cipher "NULL" -Remediate

        This will check that the Cipher\NULL property "Enabled" exists, and ensure its set to 0.
        If not it will remediate it by ensuring the key, property, and value are all created and
        set.
    .EXAMPLE
        Set-PCI32 -CipherSuite 'TLS_AES_256_GCM_SHA384'

        This will check that Get-TlsCipherSuite -Name 'TLS_AES_256_GCM_SHA384' does not return a value,
        indicating that it is disabled.
        If not it will return $false.
    .EXAMPLE
        Set-PCI32 -CipherSuite 'TLS_AES_256_GCM_SHA384' -Remediate

        This will check that Get-TlsCipherSuite -Name 'TLS_AES_256_GCM_SHA384' does not return a value,
        indicating that it is disabled.
        If not it will remediate it by ensuring the key, property, and value are all created and
        set.
    .NOTES
        Name:      Set-PCI32.ps1
        Author:    Ahnamataeus Vex
        Version: 1.0.0
        Release Date: 2022-05-16
            Updated:
                Version 1.0.1: 2022.05.17
                    Added the $CipherSuiteSet ParameterSet
                    Added the $CipherSuite parameter, with a ValidateSet list, for validation and remediation
        To-Do:
            - Add support for Intune Proactive Remediations
            - Instead of just disabling, add a toggle for Enable/Disable
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName="ProtocolSet",Position=0)]
        [ValidateSet(
            'Multi-Protocol Unified Hello',
            'PCT 1.0',
            'SSL 2.0',
            'SSL 3.0',
            'TLS 1.0',
            'TLS 1.1',
            'TLS 1.2'
        )]
        [string]
        $Protocol,
        [Parameter(Mandatory=$true,ParameterSetName="ProtocolSet",Position=1)]
        [ValidateSet(
            'Client',
            'Server'
        )]
        [string]
        $SubProtocol,
        [Parameter(Mandatory=$true,ParameterSetName="ProtocolSet",Position=2)]
        [ValidateSet(
            'Enabled',
            'DisabledByDefault'
        )]
        [string]
        $ProtocolProperty,
        [Parameter(Mandatory=$true,ParameterSetName="CipherSet",Position=0)]
        [ValidateSet(
            'AES 128/128',
            'AES 256/256',
            'DES 56/56',
            'NULL',
            'RC2 128/128',
            'RC2 40/128',
            'RC2 56/128',
            'RC4 128/128',
            'RC4 40/128',
            'RC4 56/128',
            'RC4 64/128',
            'Triple DES 168'
        )]
        [string]
        $Cipher,
        [Parameter(Mandatory=$true,ParameterSetName="CipherSuiteSet",Position=0)]
        [ValidateSet(
            'TLS_AES_256_GCM_SHA384',
            'TLS_AES_128_GCM_SHA256',
            'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_RSA_WITH_3DES_EDE_CBC_SHA',
            'TLS_PSK_WITH_AES_256_GCM_SHA384',
            'TLS_PSK_WITH_AES_128_GCM_SHA256',
            'TLS_PSK_WITH_AES_256_CBC_SHA384',
            'TLS_PSK_WITH_AES_128_CBC_SHA256',
            'TLS_PSK_WITH_NULL_SHA384',
            'TLS_PSK_WITH_NULL_SHA256',
            'TLS_RSA_WITH_NULL_SHA256',
            'TLS_RSA_WITH_NULL_SHA'
        )]
        [string]
        $CipherSuite,
        [Parameter()]
        [ValidateSet(
            'Enable',
            'Disable'
        )]
        [string]
        $Toggle,
        [Parameter()]
        [switch]
        $Remediate
    )

    # Set the HKLM
    $hklm = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\'

    # Start Protocol section
    If ($ProtocolSet) {
        # Build the protocols path
        $protocolPath = $hklm + "Protocols\" + $Protocol + "\" + $SubProtocol

        # Set the $Value based on $ProtocolProperty being "Enabled"
        If ($ProtocolProperty -eq 'Enabled') {
            # If the $Protocol does not equal TLS 1.2, set the value to 0 (Disabled)
            If ($Protocol -ne 'TLS 1.2') {
                $value = "0"
            }
            # Otherwise, set the value to 1 (Enabled)
            Else {
                $value = "1"
            }
        }
        # Set the $Value based on $ProtocolProperty being "DisabledByDefault"
        ElseIf ($ProtocolProperty -eq 'DisabledByDefault') {
            # If the $Protocol does not equal TLS 1.2, set the value to 1
            If ($Protocol -ne 'TLS 1.2') {
                $value = "1"
            }
            Else {
                # Otherwise, set the value to 0 (Disabled)
                $value = "0"
            }
        }
        
        # Test if the property exists
        If (!(Get-ItemProperty -Path $protocolPath -Name $ProtocolProperty -ErrorAction SilentlyContinue)) {
            # Property does not exist
            # Validate if remediation is requested
            If ($Remediate) {
                # Remediation requested
                # Test if the path itself exists
                If (!(Test-Path $protocolPath)) {
                    # It does not, build it
                    New-Item -Path $protocolPath -Force | Out-Null
                    # Create the property and value
                    New-ItemProperty -Path $protocolPath -Name $ProtocolProperty -Value $Value -PropertyType DWORD -Force | Out-Null
                }
                Else {
                    # The path exists; create and set the property value
                    New-ItemProperty -Path $protocolPath -Name $ProtocolProperty -Value $Value -PropertyType DWORD -Force | Out-Null
                }
            }
            Else {
                # It does not exist, and remediation not requested; exit 1
                exit 1
            }
        }
        Else {
            # Property exists
            # Checking the property value
            If (!((Get-ItemPropertyValue -Path $protocolPath -Name $ProtocolProperty -ErrorAction SilentlyContinue) -eq $Value)) {
                # The property value does not match
                If ($Remediate) {
                    # Remediation requested
                    # Create/Set the property and value
                    New-ItemProperty -Path $protocolPath -Name $ProtocolProperty -Value $Value -PropertyType DWORD -Force | Out-Null
                }
                Else {
                    # It is not the same, and remediation not requested; exit 1
                    exit 1
                }
            }
            Else {
                # The property value matches; exit 0
                exit 0
            }
        }
    } # End Protocol section
    # Start Cipher section
    ElseIf ($CipherSet) {
        # Build the ciphers path
        $cipherKey = "SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers"
        $cipherPath = $hklm + 'Ciphers\' + $Cipher

        # If the $Ciper equals "AES 128/125", "AES 256/256", or "Triple DES 168", the set the value to 1 (Enabled)
        # The $Cipher does not have a DisabledByDefault Property set, so no need to filter by it
        If (($Cipher -eq 'AES 128/128') -or ($Cipher -eq 'AES 256/256') -or ($Cipher -eq 'Triple DES 168')) {
            $value = "1"
        }
        # Otherwise, set the value to 0 (Disabled)
        Else {
            $value = "0"
        }

        # Test if the property exists
        If (!(Get-ItemProperty -Path $cipherPath -Name "Enabled" -ErrorAction SilentlyContinue)) {
            # Property does not exist
            # Validate if remediation is requested
            If ($Remediate) {
                # Remediation requested
                # Test if the path itself exists
                If (!(Test-Path $cipherPath)) {
                    # It does not, build 
                    # Because some of the Cipher names have a "/" in them, New-Item will split them up into
                    # directories. Annoying, but we need to use the method below to create them.
                    $key = (Get-Item HKLM:\).OpenSubKey($cipherKey, $true)
                    $key.CreateSubKey($cipher) | Out-Null
                    $key.Close()
                    # New-Item -Path $hklmCipherPath -Name $cipher -Force | Out-Null # DOES NOT WORK; creates separate folders for Cipher names with "/"
                    # Create the property and value
                    New-ItemProperty -Path $cipherPath -Name "Enabled" -Value $Value -PropertyType DWORD -Force | Out-Null
                }
                Else {
                    # The path exists; create and set the property value
                    New-ItemProperty -Path $cipherPath -Name "Enabled" -Value $Value -PropertyType DWORD -Force | Out-Null
                }
            }
            Else {
                # It does not exist, and remediation not requested; exit 1
                exit 1
            }
        }
        Else {
            # Property exists
            # Checking the property value
            If (!((Get-ItemPropertyValue -Path $cipherPath -Name "Enabled" -ErrorAction SilentlyContinue) -eq $Value)) {
                # The property value does not match
                If ($Remediate) {
                    # Remediation requested
                    # Create/Set the property and value
                    New-ItemProperty -Path $cipherPath -Name "Enabled" -Value $Value -PropertyType DWORD -Force | Out-Null
                }
                Else {
                    # It is not the same, and remediation not requested; exit 1
                    exit 1
                }
            }
            Else {
                # The property value matches; exit 0
                exit 0
            }
        }
    } # End Cipher section
    # Start Cipher Suite section
    Else {
        # Things get a bit ugly here as there is a regkey that can cause the *-TlsCipherSuite commands to not report/work properly
        If (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -Name Functions -ErrorAction SilentlyContinue) { 
            # The key exists; blow it away
            Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -Name Functions -Force
        }
        # Check if the Cipher Suite is enabled
        If (Get-TlsCipherSuite -Name $CipherSuite) {
            # The Cipher was detected as enabled
            If ($Remediate) {
                # Remediation requested; disabling the Cipher Suite
                Disable-TlsCipherSuite -Name $CipherSuite
            }
            Else {
                # It is enabled, and remediation not requested; exit 1
                exit 1
            }
        }
        Else {
            # The Cipher Suite is not detected; exit 0
            exit 0
        }
    } # End Cipher Suite section
}

Set-PCI32 -Protocol 'SSL 3.0' -SubProtocol Client -ProtocolProperty DisabledByDefault