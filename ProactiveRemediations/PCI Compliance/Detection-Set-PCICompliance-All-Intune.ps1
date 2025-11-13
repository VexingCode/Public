Function Set-PCICompliance {
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
            'TLS 1.2',
            'TLS 1.3'
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
            'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256',
            'TLS_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_RSA_WITH_AES_256_CBC_SHA256',
            'TLS_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_RSA_WITH_AES_256_CBC_SHA',
            'TLS_RSA_WITH_AES_128_CBC_SHA',
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
        [Parameter(Mandatory=$true,ParameterSetName="HashSet",Position=0)]
        [ValidateSet(
            'MD5',
            'SHA',
            'SHA256',
            'SHA384',
            'SHA512'
        )]
        [string]
        $Hash,
        [Parameter(Mandatory=$true,ParameterSetName="KeyExAlgSet",Position=0)]
        [ValidateSet(
            'Diffie-Hellman',
            'ECDH',
            'PKCS'
        )]
        [string]
        $KeyExchangeAlgorithm,
        [Parameter(Mandatory=$true,ParameterSetName='KeyExAlgSet',Position=1)]
        [ValidateSet(
            'Enabled',
            'ServerMinKeyBitLength'
        )]
        [string]
        $KEAProperty,
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

    # Set Defaults
    $CipherSuiteDefaults = @{
        'TLS_AES_256_GCM_SHA384' = $true
        'TLS_AES_128_GCM_SHA256' = $true
        'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384' = $true
        'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256' = $true
        'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384' = $true
        'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256' = $true
        'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384' = $true
        'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256' = $true
        'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384' = $true
        'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256' = $true
        'TLS_RSA_WITH_AES_256_GCM_SHA384' = $false
        'TLS_RSA_WITH_AES_128_GCM_SHA256' = $false
        'TLS_RSA_WITH_AES_256_CBC_SHA256' = $false
        'TLS_RSA_WITH_AES_128_CBC_SHA256' = $false
        'TLS_RSA_WITH_AES_256_CBC_SHA' = $false
        'TLS_RSA_WITH_AES_128_CBC_SHA' = $false
        'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384' = $false
        'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256' = $false
        'TLS_RSA_WITH_3DES_EDE_CBC_SHA' = $false
        'TLS_PSK_WITH_AES_256_GCM_SHA384' = $false
        'TLS_PSK_WITH_AES_128_GCM_SHA256' = $false
        'TLS_PSK_WITH_AES_256_CBC_SHA384' = $false
        'TLS_PSK_WITH_AES_128_CBC_SHA256' = $false
        'TLS_PSK_WITH_NULL_SHA384' = $false
        'TLS_PSK_WITH_NULL_SHA256' = $false
        'TLS_RSA_WITH_NULL_SHA256' = $false
        'TLS_RSA_WITH_NULL_SHA' = $false
    }

    # Start Protocol section
    If ($PsCmdlet.ParameterSetName -eq "ProtocolSet") {
        # Build the protocols path
        $protocolPath = $hklm + "Protocols\" + $Protocol + "\" + $SubProtocol

        # Set the $Value based on $ProtocolProperty being "Enabled"
        If ($ProtocolProperty -eq 'Enabled') {
            # If the $Protocol does not equal TLS 1.2 or TLS 1.3, set the value to 0 (Disabled)
            If ($Protocol -ne 'TLS 1.2' -and $Protocol -ne 'TLS 1.3') {
                $value = "0"
            } Else {
                # Otherwise, set the value to 4294967295 (Enabled)
                $value = "4294967295"
            }
        }
        # Set the $Value based on $ProtocolProperty being "DisabledByDefault"
        ElseIf ($ProtocolProperty -eq 'DisabledByDefault') {
            # If the $Protocol does not equal TLS 1.2 or TLS 1.3, set the value to 1
            If ($Protocol -ne 'TLS 1.2' -and $Protocol -ne 'TLS 1.3') {
                $value = "1"
            } Else {
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
                } Else {
                    # The path exists; create and set the property value
                    New-ItemProperty -Path $protocolPath -Name $ProtocolProperty -Value $Value -PropertyType DWORD -Force | Out-Null
                }
            } Else {
                # It does not exist, and remediation not requested; $global:Results += $false
                Write-Output "NON-COMPLIANT: The '$ProtocolProperty' property does not exist at '$protocolPath'. Remediation not requested. Exiting 1 for non-compliant."
                $global:Results += $false
            }
        } Else {
            # Property exists
            # Checking the property value
            If (!((Get-ItemPropertyValue -Path $protocolPath -Name $ProtocolProperty -ErrorAction SilentlyContinue) -eq $Value)) {
                # The property value does not match
                If ($Remediate) {
                    # Remediation requested
                    # Create/Set the property and value
                    New-ItemProperty -Path $protocolPath -Name $ProtocolProperty -Value $Value -PropertyType DWORD -Force | Out-Null
                } Else {
                    # It is not the same, and remediation not requested; $global:Results += $false
                    Write-Output "NON-COMPLIANT: The value of '$ProtocolProperty', at '$protocolPath', does not equal '$value'. Remediation not requested. Exiting 1 for non-compliant."
                    $global:Results += $false
                }
            } Else {
                # The property value matches; $global:Results += $true
                Write-Output "COMPLIANT: The value of '$ProtocolProperty', at '$protocolPath', equals '$value'. Exiting 0 for compliant."
                $global:Results += $true
            }
        }
    } # End Protocol section
    # Start Cipher section
    ElseIf ($PsCmdlet.ParameterSetName -eq "CipherSet") {
        # Build the ciphers path
        $cipherKey = "SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers"
        $cipherPath = $hklm + 'Ciphers\' + $Cipher

        # If the $Ciper equals "AES 128/125", "AES 256/256", or "Triple DES 168", the set the value to 4294967295 (Enabled)
        # The $Cipher does not have a DisabledByDefault Property set, so no need to filter by it
        If (($Cipher -eq 'AES 128/128') -or ($Cipher -eq 'AES 256/256') -or ($Cipher -eq 'Triple DES 168')) {
            $value = "4294967295"
        } Else {
            # Otherwise, set the value to 0 (Disabled)
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
                } Else {
                    # The path exists; create and set the property value
                    New-ItemProperty -Path $cipherPath -Name "Enabled" -Value $Value -PropertyType DWORD -Force | Out-Null
                }
            } Else {
                # It does not exist, and remediation not requested; $global:Results += $false
                Write-Output "NON-COMPLIANT: The 'Enabled' property does not exist at '$cipherPath'. Remediation not requested. Exiting 1 for non-compliant."
                $global:Results += $false
            }
        } Else {
            # Property exists
            # Checking the property value
            If (!((Get-ItemPropertyValue -Path $cipherPath -Name "Enabled" -ErrorAction SilentlyContinue) -eq $Value)) {
                # The property value does not match
                If ($Remediate) {
                    # Remediation requested
                    # Create/Set the property and value
                    New-ItemProperty -Path $cipherPath -Name "Enabled" -Value $Value -PropertyType DWORD -Force | Out-Null
                } Else {
                    # It is not the same, and remediation not requested; $global:Results += $false
                    Write-Output "NON-COMPLIANT: The value of 'Enabled', at '$cipherPath', does not equal '$value'. Remediation not requested. Exiting 1 for non-compliant."
                    $global:Results += $false
                }
            } Else {
                # The property value matches; $global:Results += $true
                Write-Output "COMPLIANT: The value of 'Enabled', at '$cipherPath', equals '$value'. Exiting 0 for compliant."
                $global:Results += $true
            }
        }
    } # End Cipher section
    # Start Hashes section
    ElseIf ($PsCmdlet.ParameterSetName -eq "HashSet") {
        # Build the Hashes path
        $hashPath = $hklm + 'Hashes\' + $Hash

        # Build the Hashes value
        $value = '4294967295'

        # Test if the property exists
        If (!(Get-ItemProperty -Path $hashPath -Name "Enabled" -ErrorAction SilentlyContinue)) {
            # Property does not exist
            # Validate if remediation is requested
            If ($Remediate) {
                # Remediation requested
                # Test if the path itself exists
                If (!(Test-Path $hashPath)) {
                    # It does not, build it
                    New-Item -Path $hashPath -Force | Out-Null
                    # Create the property and value
                    New-ItemProperty -Path $hashPath -Name "Enabled" -Value $value -PropertyType DWORD -Force | Out-Null
                } Else {
                    # The path exists; create and set the property value
                    New-ItemProperty -Path $hashPath -Name "Enabled" -Value $value -PropertyType DWORD -Force | Out-Null
                }
            } Else {
                # It does not exist, and remediation not requested; $global:Results += $false
                Write-Output "NON-COMPLIANT: The 'Enabled' property does not exist at '$hashPath'. Remediation not requested. Exiting 1 for non-compliant."
                $global:Results += $false
            }
        } Else {
            # Property exists
            # Checking the property value
            If (!((Get-ItemPropertyValue -Path $hashPath -Name "Enabled" -ErrorAction SilentlyContinue) -eq $value)) {
                # The property value does not match
                If ($Remediate) {
                    # Remediation requested
                    # Create/Set the property and value
                    New-ItemProperty -Path $hashPath -Name "Enabled" -Value $value -PropertyType DWORD -Force | Out-Null
                }
                Else {
                    # It is not the same, and remediation not requested; $global:Results += $false
                    Write-Output "NON-COMPLIANT: The value of 'Enabled', at '$hashPath', does not equal '$value'. Remediation not requested. Exiting 1 for non-compliant."
                    $global:Results += $false
                }
            }
            Else {
                # The property value matches; $global:Results += $true
                Write-Output "COMPLIANT: The value of 'Enabled', at '$hashPath', equals '$value'. Exiting 0 for compliant."
                $global:Results += $true
            }
        }
    } # End Hashes section
    # Start KeyExchangeAlgorithms section
    ElseIf ($PsCmdlet.ParameterSetName -eq "KeyExAlgSet") {
        # Build the KeyExchangeAlgorithms path
        $keaPath = $hklm + 'KeyExchangeAlgorithms\' + $KeyExchangeAlgorithm

        # Set the $Value based on $keaProperty being "Enabled"
        If ($keaProperty -eq 'Enabled') {
            $value = "4294967295"
        } ElseIf ($keaProperty -eq 'ServerMinKeyBitLength') {
            # Set the $Value based on $keaProperty being "ServerMinKeyBitLength"
            $value = "2048"
        }

        # Validate that ServerMinKeyBitLength is oly being selected for Diffie-Hellman
        If (($KeyExchangeAlgorithm -ne 'Diffie-Hellman') -and ($KEAProperty -eq 'ServerMinKeyBitLength')) {
            # ServerMinKeyBitLength only valid for Diffie-Hellman. Returning.
            return
        } Else {
            # Test if the property exists
            If (!(Get-ItemProperty -Path $keaPath -Name $keaProperty -ErrorAction SilentlyContinue)) {
                # Property does not exist
                # Validate if remediation is requested
                If ($Remediate) {
                    # Remediation requested
                    # Test if the path itself exists
                    If (!(Test-Path $keaPath)) {
                        # It does not, build it
                        New-Item -Path $keaPath -Force | Out-Null
                        # Create the property and value
                        New-ItemProperty -Path $keaPath -Name $keaProperty -Value $value -PropertyType DWORD -Force | Out-Null
                    } Else {
                        # The path exists; create and set the property value
                        New-ItemProperty -Path $keaPath -Name $keaProperty -Value $value -PropertyType DWORD -Force | Out-Null
                    }
                } Else {
                    # It does not exist, and remediation not requested; $global:Results += $false
                    Write-Output "NON-COMPLIANT: The '$keaProperty' property does not exist at '$keaPath'. Remediation not requested. Exiting 1 for non-compliant."
                    $global:Results += $false
                }
            } Else {
                # Property exists
                # Checking the property value
                If (!((Get-ItemPropertyValue -Path $keaPath -Name $keaProperty -ErrorAction SilentlyContinue) -eq $value)) {
                    # The property value does not match
                    If ($Remediate) {
                        # Remediation requested
                        # Create/Set the property and value
                        New-ItemProperty -Path $keaPath -Name $keaProperty -Value $value -PropertyType DWORD -Force | Out-Null
                    } Else {
                        # It is not the same, and remediation not requested; $global:Results += $false
                        Write-Output "NON-COMPLIANT: The value of '$keaProperty', at '$keaPath', does not equal '$value'. Remediation not requested. Exiting 1 for non-compliant."
                        $global:Results += $false
                    }
                } Else {
                    # The property value matches; $global:Results += $true
                    Write-Output "COMPLIANT: The value of '$keaProperty', at '$keaPath', equals '$value'. Exiting 0 for compliant."
                    $global:Results += $true
                }
            }
        }
    } # End KeyExchangeAlgorithms
    # Start Cipher Suite section
    Else {
        # Things get a bit ugly here as there is a regkey that can cause the *-TlsCipherSuite commands to not report/work properly
        If (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -Name Functions -ErrorAction SilentlyContinue) { 
            # The key exists; blow it away
            Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -Name Functions -Force
        }

        # Validate if the Cipher Suite exists in the default hash table
        If ($CipherSuite -in $CipherSuiteDefaults.Keys) {
            $suiteDefault = $CipherSuiteDefaults.$CipherSuite
        
            If ($suiteDefault -eq $true) {
                # The cipher suite should be enabled
                If (Get-TlsCipherSuite -Name $CipherSuite) {
                    # The cipher suite is enabled; $global:Results += $true
                    Write-Output "COMPLIANT: The '$CipherSuite' Cipher Suite is enabled. Exiting 0 for compliant."
                    $global:Results += $true
                } Else {
                    # The cipher suite is not enabled; remediate or $global:Results += $false
                    If ($Remediate) {
                        # Remediation requested; enabling the cipher suite
                        Enable-TlsCipherSuite -Name $CipherSuite
                    } Else {
                        # Remediation not requested; $global:Results += $false
                        Write-Output "The 'NON-COMPLIANT: $CipherSuite' Cipher Suite should be enabled, but is not. Remediation not requested. Exiting 1 for non-compliant."
                        $global:Results += $false
                    }
                }
            } Else {
                # The cipher suite should be disabled
                If (Get-TlsCipherSuite -Name $CipherSuite) {
                    # The cipher suite is enabled; remediate or $global:Results += $false
                    If ($Remediate) {
                        # Remediation requested; disabling the cipher suite
                        Disable-TlsCipherSuite -Name $CipherSuite
                    } Else {
                        # Remediation not requested; $global:Results += $false
                        Write-Output "NON-COMPLIANT: The '$CipherSuite' Cipher Suite should be disabled, but is not. Remediation not requested. Exiting 1 for non-compliant."
                        $global:Results += $false
                    }
                } Else {
                    # The cipher suite is disabled; $global:Results += $true
                    Write-Output "COMPLIANT: The '$CipherSuite' Cipher Suite is disabled. Exiting 0 for compliant."
                    $global:Results += $true
                }
            }
        } Else {
            # Invalid cipher suite; $global:Results += $false
            Write-Output "NON-COMPLIANT: Invalid Cipher Suite specified."
            $global:Results += $false
        }
    } # End Cipher Suite section
}

$results = @()
$ciphers = 'AES 128/128','AES 256/256','DES 56/56','NULL','RC2 128/128','RC2 40/128','RC2 56/128','RC4 128/128','RC4 40/128','RC4 56/128','RC4 64/128','Triple DES 168'
$cipherSuites = 'TLS_AES_256_GCM_SHA384','TLS_AES_128_GCM_SHA256','TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384','TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256','TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384','TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256','TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384','TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256','TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384','TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256','TLS_RSA_WITH_AES_256_GCM_SHA384','TLS_RSA_WITH_AES_128_GCM_SHA256','TLS_RSA_WITH_AES_256_CBC_SHA256','TLS_RSA_WITH_AES_128_CBC_SHA256','TLS_RSA_WITH_AES_256_CBC_SHA','TLS_RSA_WITH_AES_128_CBC_SHA','TLS_DHE_RSA_WITH_AES_256_GCM_SHA384','TLS_DHE_RSA_WITH_AES_128_GCM_SHA256','TLS_RSA_WITH_3DES_EDE_CBC_SHA','TLS_PSK_WITH_AES_256_GCM_SHA384','TLS_PSK_WITH_AES_128_GCM_SHA256','TLS_PSK_WITH_AES_256_CBC_SHA384','TLS_PSK_WITH_AES_128_CBC_SHA256','TLS_PSK_WITH_NULL_SHA384','TLS_PSK_WITH_NULL_SHA256','TLS_RSA_WITH_NULL_SHA256','TLS_RSA_WITH_NULL_SHA'
$protocols = 'Multi-Protocol Unified Hello','PCT 1.0','SSL 2.0','SSL 3.0','TLS 1.0','TLS 1.1','TLS 1.2'
$subProtocols = 'Client','Server'
$protocolProperties = 'Enabled','DisabledByDefault'
$hashes = 'MD5','SHA','SHA256','SHA384','SHA512'
$keas = 'Diffie-Hellman','ECDH','PKCS'
$keaprops = 'Enabled','ServerMinKeyBitLength'

# Set all of the Protocols

# Loop through the protocols
ForEach ($p in $protocols) {
    # Loop through the sub-protocols
    ForEach ($s in $subProtocols) {
        # Loop through the protocol properties
        ForEach ($pp in $protocolProperties) {
            Set-PCICompliance -Protocol $p -SubProtocol $s -ProtocolProperty $pp -Verbose # -Remediate
        }
    }
}

# Set all of the Ciphers

# Loop through the Ciphers
ForEach ($c in $ciphers) {
    Set-PCICompliance -Cipher $c -Verbose # -Remediate
}

# Set all of the CipherSuites

# Loop through the CipherSuites
ForEach ($cs in $cipherSuites) { 
    Set-PCICompliance -CipherSuite $cs -Verbose # -Remediate
}

# Set all of the Hashes

# Loop through the Hashes
ForEach ($h in $hashes) {
    Set-PCICompliance -Hash $h -Verbose # -Remediate
}

# Set all of the Key Exchange Algorithms

# Loop through the Key Exchange Algorithms
ForEach ($k in $keas) {
    # Loop through the Key Exchange Algorithm properties
    ForEach ($kp in $keaprops) {
        Set-PCICompliance -KeyExchangeAlgorithm $k -KEAProperty $kp # -Remediate
    }
}

If ($results | Where-Object {$_ -eq $false} ) {
    exit 1
} Else {
    Write-Output 'All settings configured.'
    exit 0
}