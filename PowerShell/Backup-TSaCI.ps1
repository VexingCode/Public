<#

.SYNOPSIS
  Backup all task sequences to disk greater than $minDate

.DESCRIPTION
  TS backup will fail if TS name has special characters not allowed, edit sitecode and destinationpath

.PARAMETER <Parameter_Name>
  None

.INPUTS
  None

.OUTPUTS
  None

.NOTES
  Version:        4.0
  Author:         dpadgett/https://execmgr.net
  Creation Date:  270617
  Purpose/Change: Initial script development

  Version:        4.1
  Author:         Ahnamataeus Vex
  Creation Date:  281117
  Purpose/Change: Added CI exports; also deletion of folders older than 14 days

.EXAMPLE
  None

#>


# Site configuration
$SiteCode = "SMS" # Site code 
$ProviderMachineName = "cm.domain.com" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

[datetime]$minDate = "1/1/2017 00:00:00 AM"

$ts = Get-CMTaskSequence | Where-Object {$_.SourceDate -gt $minDate}
$ci = Get-CMConfigurationItem
$Tasks = Get-ScheduledTask -TaskPath "\"

$time = get-date -format ddMMyyyy

$tsPath = "I:\Packages$\Backup\TS"
$ciPath = "I:\Packages$\Backup\CI"
$tasksPath = "I:\Packages$\Backup\Tasks"

If(!(Test-Path "$tsPath\$time")){
    New-Item -Path "$tsPath\$time" -ItemType Directory -Verbose
    }
If(!(Test-Path "$ciPath\$time")){
    New-Item -Path "$ciPath\$time" -ItemType Directory -Verbose
    }
If(!(Test-Path "$tasksPath\$time")){
    New-Item -Path "$tasksPath\$time" -ItemType Directory -Verbose
    }

ForEach ($t in $ts){
     
     $exportTS = $t.Name
     Export-CMTaskSequence -TaskSequencePackageId $t.PackageID -ExportFilePath "$tsPath\$time\$exportTS.zip" -Verbose
     }

ForEach ($c in $ci) {
    $exportCI = $c.LocalizedDisplayName
    Export-CMConfigurationItem -InputObject $c -Path "$ciPath\$time\$exportCI.cab" -Verbose
}

$exportPath = "$tasksPath\$time"

ForEach ($Task in $Tasks) {
    Export-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath | Out-File (Join-Path $exportPath "$($Task.TaskName).xml")
    }

Get-ChildItem $tsPath | Where-Object {$_.PSIsContainer -and $_.LastWriteTime -le (Get-Date).AddDays(-30)} |% {Remove-Item $_ -Force}
Get-ChildItem $ciPath | Where-Object {$_.PSIsContainer -and $_.LastWriteTime -le (Get-Date).AddDays(-30)} | % {Remove-Item $_ -Force}
Get-ChildItem $tasksPath | Where-Object {$_.PSIsContainer -and $_.LastWriteTime -le (Get-Date).AddDays(-30)} | % {Remove-Item $_ -Force}