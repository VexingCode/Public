<#
.SYNOPSIS
    Saves a backup of specified GPOs and converts them to a .PolicyRule file.
.DESCRIPTION
    This script will run a backup on a Group Policy Object, and save it to the specified location. It
    will then convert that backup into a .PolicyRules file that can be imported into the Policy Analyzer
    for viewing.

    It is designed to be used in conjunction with the Microsoft PolicyAnalyzer, available in the Microsoft
    Security Compliance Toolkit: https://www.microsoft.com/en-us/download/details.aspx?id=55319

    Specifically, the GPO2PolicyRules.exe is the tool used to do the actual conversion of the exported GPOs to
    .PolicyRules files.
.PARAMETER DisplayName
    Specifies the name of the GPO you want to export. This parameter accepts the pipeline from the native
    cmdlet "Get-GPO". If multiple GPOs are specified, or returned from the pipeline, it will run through them
    all.
.PARAMETER G2PexePath
    Specifies the location of the GPO2PolicyRule.exe file. If this parameter is not specified, then the
    script will check the Present Working Directory for it and use that, if found. If it is not found, it
    will throw and error.
.PARAMETER BackupPath
    Specifies the location where you would like the backup files from GPO to be saved.
.PARAMETER PolicyRulesPath
    Specifies the location where you would like the final .PolicyRule files to be saved.
.EXAMPLE
    C:\Windows\System32> Convert-GPOtoPolicyRule -DisplayName "Some.Group.Policy" -G2PexePath "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" -BackupPath "C:\Tools\GPOBackups" -PolicyRulesPath "C:\Tools\PolicyAnalyzer\PolicyRules"
    
    This example exports the GPO named "Some.Group.Policy" to "C:\Tools\GPOBackups\$DisplayName", then runs
    the GPO2PolicyRule.exe from "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" to convert the file to a 
    .PolicyRule. It will then be saved to "C:\Tools\PolicyAnalyzer\PolicyRules" as $DisplayName.PolicyRule.
.EXAMPLE
    C:\Windows\System32> Convert-GPOtoPolicyRule -DisplayName "Some.Group.Policy" -G2PexePath "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" -BackupPath "C:\Tools\GPOBackups" -PolicyRulesPath "C:\Tools\PolicyAnalyzer\PolicyRules"
    
    This example exports the GPO named "Some.Group.Policy" to "C:\Tools\GPOBackups\$DisplayName". Due to the
    -G2PexePath not being specified, it will look in "C:\Windows\System32" (Present Working Directory) for the
    .exe file. If it is not found, it will throw an error. If it is found, it then runs the GPO2PolicyRule.exe
    to convert the file to a .PolicyRule. It will then be saved to "C:\Tools\PolicyAnalyzer\PolicyRules" as 
    $DisplayName.PolicyRule.
.EXAMPLE
    C:\Windows\System32> Convert-GPOtoPolicyRule -DisplayName "Some.Group.Policy","Some.Group.Policy.2" -G2PexePath "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" -BackupPath "C:\Tools\GPOBackups" -PolicyRulesPath "C:\Tools\PolicyAnalyzer\PolicyRules"

    This example exports both GPOs, "Some.Group.Policy" and "Some.Group.Policy.2" to "C:\Tools\GPOBackups\$DisplayName",
    then runs the GPO2PolicyRule.exe from "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" to convert them to 
    .PolicyRule files. They will then be saved to "C:\Tools\PolicyAnalyzer\PolicyRules" as $DisplayName.PolicyRule.
.EXAMPLE
    C:\Windows\System32> Get-GPO -Name "Some.Group.Policy" | Convert-GPOtoPolicyRule -G2PexePath "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" -BackupPath "C:\Tools\GPOBackups" -PolicyRulesPath "C:\Tools\PolicyAnalyzer\PolicyRules"

    This example pipes the GPO named "Some.Group.Policy" from the "Get-GPO" cmdlet, to the Convert-GPOtoPolicyRule
    cmdlet. It will then be exported to "C:\Tools\GPOBackups\$DisplayName" and runs the GPO2PolicyRule.exe 
    from "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" to convert the file to a .PolicyRule. It will be saved to 
    "C:\Tools\PolicyAnalyzer\PolicyRules" as $DisplayName.PolicyRule.
.EXAMPLE
    C:\Windows\System32> Get-GPO -All | Where-Object {$_.DisplayName -match 'CoS.'} | Convert-GPOtoPolicyRule -G2PexePath "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" -BackupPath "C:\Tools\GPOBackups" -PolicyRulesPath "C:\Tools\PolicyAnalyzer\PolicyRules"

    This example utilizes "Get-GPO" to find and pipe all GPOs with "CoS." in their names. The Convert-GPOtoPolicyRule
    cmdlet will export them to "C:\Tools\GPOBackups\$DisplayName" and run the GPO2PolicyRule.exe from 
    "C:\Tools\PolicyAnalyzer\PolicyAnalyzer_40" to convert the backups to .PolicyRule files. They will be saved
    to "C:\Tools\PolicyAnalyzer\PolicyRules" as $DisplayName.PolicyRule.
.NOTES
    Name:           Convert-GPOtoPolicyRule.ps1
    Author:         Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2022-07-22
    To-Do:
        - Add functionality to test if the local folder has the toolkit; if not, download, extract, and run 
        from there
        - Probably more error handling
#>

<#
#Requires -Modules GroupPolicy
#Requires -RunAsAdministrator
#>

Function Convert-GPOtoPolicyRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName)]
        [string[]]
        $DisplayName,
        [Parameter(Position=1)]
        [string]
        $G2PexePath,
        [Parameter(Mandatory=$true,Position=2)]
        [string]
        $BackupPath,
        [Parameter(Mandatory=$true,Position=3)]
        [string]
        $PolicyRulesPath
    )

    Begin {

        # Check for GroupPolicy Module
        If (!(Get-Module -Name GroupPolicy)) {
            Write-Warning "You do not have the Group Policy module. Please ensure you have RSAT installed."
            Break
        }

        # Check for elevation; throw error if not
        If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
            Break
        }

        # Validate the GPO2PolicyRules.exe location
        If (!($G2PexePath)) {
            Write-Host "No directory specified for the GPO2PolicyRules.exe. Searching in the Preset Working Path."
            # Set the Present Working Directory
            $pwdPath = $PWD.Path
            Write-Host "Present Working Path is: $pwdPath"
            Write-Host "Testing the PWD for GPO2PolicyRules.exe"
            If (Test-Path $pwdPath\GPO2PolicyRules.exe) {
                Write-Host "GPO2PolicyRules.exe found."
                $g2pExe = "$pwdPath\GPO2PolicyRules.exe"
                Write-Host "Setting the exe variable to `"$g2pExe`""
            }
            Else {
                Throw "$G2PexePath is null, and the GPO2PolicyRules.exe does not exist at the script root. Please specify the correct exe location."
            }
        }
        Else {
            Write-Host "GPO2PolicyRules.exe directory specified. Searching for the exe..."
            If (Test-Path $G2PexePath\GPO2PolicyRules.exe) {
                Write-Host "GPO2PolicyRules.exe found in $G2PexePath"
                $g2pExe = "$G2PexePath\GPO2PolicyRules.exe"
                Write-Host "Setting the exe variable to $g2pExe"
            }
            Else {
                Throw "The GPO2PolicyRules.exe does not exist in the specified location. Please specify the correct exe location."
            }
        }

    }
    Process {
        ForEach ($gpo in $DisplayName) {
            
            # Set the GPO folder for the export
            $gpoPath = "$BackupPath\$gpo"
            Write-Host "Setting the GPO backup save location to $gpoPath"

            # Test if the path already exists
            Write-Host "Testing if the directory already exists."
            If(Test-Path $gpoPath) {
                # It does, so nuke it
                Write-Host "Directory exists; nuking it from orbit...its the only way to be sure."
                Remove-Item -Path $gpoPath -Force -Recurse | Out-Null
                # Recreate the directory
                Write-Host "Recreating the directory: $gpoPath"
                New-Item -Path $gpoPath -ItemType Directory | Out-Null
            }
            Else {
                Write-Host "The directory does not exist. Creating $gpoPath"
                # It does not; create the directory
                New-Item -Path $gpoPath -ItemType Directory -Force | Out-Null
            }

            # Backup the GPOs to the folder
            Write-Host "Backing up $gpo to $gpoPath."
            Backup-GPO -Name $gpo -Path $gpoPath | Out-Null

            # Test if the .PolicyRules file already exists in the specified location
            $policyRulesFile = "$PolicyRulesPath\$gpo.PolicyRules"
            $testStartProcess = "Start-Process -FilePath $g2pExe -ArgumentList `"`"$gpoPath`" `"$policyRulesFile`"`" -WindowStyle Hidden"
            Write-Host "Start-Process = $testStartProcess" -ForegroundColor Yellow
            Write-Host "Existential test for $policyRulesFile"
            If (Test-Path $policyRulesFile) {
                Write-Host ".PolicyRules file exists; you know what comes next..."
                Remove-Item -Path $PolicyRulesFile -Force 
                Write-Host "Converting the $gpo backup into a .PolicyRules file and saving it to $PolicyRulesPath"
                Start-Process -FilePath $g2pExe -ArgumentList "`"$gpoPath`" `"$policyRulesFile`"" -WindowStyle Hidden
            }
            Else {
                # Convert the GPO backup to a .PolicyRule file
                Write-Host "Converting the $gpo backup into a .PolicyRules file, located in $PolicyRulesPath"
                Start-Process -FilePath $g2pExe -ArgumentList "`"$gpoPath`" `"$policyRulesFile`"" -WindowStyle Hidden
            }
        }
    }
}