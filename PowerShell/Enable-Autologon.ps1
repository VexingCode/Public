<#
.SYNOPSIS
    Sets kiosk account autologon
.DESCRIPTION
    Utilizes the Autologon64.exe and Task Sequence variables to set up the autologon account for a kiosk
.INPUTS
    AutologonUsername
        The TSVar that contains the username for the kiosk account
    AutologonDomain
        The TSVar that contains the domain name for the kiosk account
    AutologonPassword
        The TSVar that contains the password for the kiosk account    
.OUTPUTS
    None
.NOTES
    Name:           Enable-Autologon.ps1
    Author:         Anthony Fontanez
    Contributor:    Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2021-12-02
#>

$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment

$AutologonUsername = $TSEnv.Value('AutologonUsername')
$AutologonDomain = $TSEnv.Value('AutologonDomain')
$AutologonPassword = $TSEnv.Value('AutologonPassword')

$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

Start-Process -FilePath "$($ScriptDirectory)\Autologon64.exe" -ArgumentList "/AcceptEula $AutologonUsername $AutologonDomain $AutologonPassword"