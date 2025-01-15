<#
.SYNOPSIS
    Enables or disables WinRM Basic Auth.
.DESCRIPTION
    Enables or disables WinRM Basic Auth by setting the appropriate regkey.
.EXAMPLE
    PS C:\> Set-WinRMBasicAuth -Toggle Enable
    Enables BasicAuth on the device.
    PS C:\> Set-WinRMBasicAuth -Toggle Disable
    Disables BasicAuth on the device.
.INPUTS
    -Toggle
    This parameter specifies if you want to enable or disable the WinRM Basic Auth feature. Below are the
    acceptable values. You can tab-complete them, and they are not case sensitive.
        'Enable'
        'Disable'
.OUTPUTS
    Status of enabling or disabling.
.NOTES
    Name:         Set-WinRMBasicAuth.ps1
    Author:       Ahnamataeus Vex
    Version:      1.0.0
    Release Date: 2022-01-06
#>

Function Set-WinRMBasicAuth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Enable','Disable')]
        [string]
        $Toggle
    )

    Switch ($Toggle) {
        'Enable' {$value = '1'}
        'Disable' {$value = '0'}
    }

    $regkey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client"
    $property =  "AllowBasic"

    If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
        Break
    }

    If ((Get-ItemProperty -Path $regkey -Name $property)) {
        Write-Output "$property exists."
        If ($value -eq '1') {
            If (!((Get-ItemProperty -Path $regkey -Name $property -ErrorAction SilentlyContinue).AllowBasic -eq $value)) {
                Write-Output "Basic Auth disabled in WinRM. Enabling it."
                Set-ItemProperty -Path $regkey -Name $property -Value $value
            }
        }
        ElseIf ($value -eq '0') {
            If (!((Get-ItemProperty -Path $regkey -Name $property -ErrorAction SilentlyContinue).AllowBasic -eq $value)) {
                Write-Output "Basic Auth enabled in WinRM. Disabling it."
                Set-ItemProperty -Path $regkey -Name $property -Value $value
            }
        }
    }
}