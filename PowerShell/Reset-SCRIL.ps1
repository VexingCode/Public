<#
.SYNOPSIS
    Rotates the SCRIL setting
.DESCRIPTION
    This script rotates the SCRIL setting for Users/Groups in ActiveDirectory, by disabling and re-enabling the setting. If the user does not have it enabled, this will enable it.
.PARAMETER User
    Use the -User parameter to specify individual(s) you would like to rotate.
.PARAMETER Group
    Use the -Group parameter to specify the name(s) of AD security groups containing users you would like to rotate.
.PARAMETER Server
    Use the -Server parameter to specify the AD server to focus on during the script. This helps ensure you don't hit multiple domain controllers that may not have replicated yet. It is a REQUIRED field.
.EXAMPLE
    PS C:\> Reset-SCRIL -User "JDoe" -Server AD1
    This will validate that the account exists, and set or rotate the SCRIL setting for them.
    PS C:\> Reset-SCRIL -User "JDoe","JaDoe" -Server AD1
    This will validate that the accounts exist, and set or rotate the SCRIL setting for them.
    PS C:\> Reset-SCRIL -Group "SECGrp1-All" -Server AD1
    This will validate that the group exists, pull the users out of it, and set or rotate the SCRIL setting for them.
    PS C:\> Reset-SCRIL -Group "SECGrp1-All","SECGrp2-All" -Server AD1
    This will validate that the groups exist, pull the users out of it, and set or rotate the SCRIL setting for them.
    PS C:\> Reset-SCRIL -User "JDoe","JaDoe" -Group "SECGrp1-All","SECGrp2-All" -Server AD1
    This will validate that the specified users and groups exist, assemble an array, then set or rotate the SCRIL setting for them.
.OUTPUTS
    A log will be created in 'C:\Windows\Logs' when the script runs.
.NOTES
    Name:           Reset-SCRIL.ps1
    Author:         Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2021-11-11
    To-Do:
        AD Module Check
        Clean up logs after X amount of days
#>

Function Reset-SCRIL {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string[]]$User,
        [Parameter(Mandatory=$false)]
        [string[]]$Group,
        [Parameter(Mandatory=$true)]
        [string]$Server
    )

    Function Write-CCMLogEntry {
        <#
            .SYNOPSIS
                Write to a log file in the CMTrace Format
            .DESCRIPTION
                The function is used to write to a log file in a CMTrace compatible format. This ensures that CMTrace or OneTrace can parse the log
                and provide data in a familiar format.
            .PARAMETER Value
                String to be added it to the log file as the message, or value
            .PARAMETER Severity
                Severity for the log entry. 1 for Informational, 2 for Warning, and 3 for Error.
            .PARAMETER Component
                Stage that the log entry is occuring in, log refers to as 'component.'
            .PARAMETER FileName
                Name of the log file that the entry will written to - note this should not be the full path.
            .PARAMETER Folder
                Path to the folder where the log will be stored.
            .PARAMETER Bias
                Set timezone Bias to ensure timestamps are accurate. This defaults to the local machines bias, but one can be provided. It can be
                helperful to gather the bias once, and store it in a variable that is passed to this parameter as part of a splat, or $PSDefaultParameterValues
            .PARAMETER MaxLogFileSize
                Maximum size of log file before it rolls over. Set to 0 to disable log rotation. Defaults to 5MB
            .PARAMETER LogsToKeep
                Maximum number of rotated log files to keep. Set to 0 for unlimited rotated log files. Defaults to 0.
            .EXAMPLE
                C:\PS> Write-CCMLogEntry -Value 'Testing Function' -Component 'Test Script' -FileName 'LogTest.Log' -Folder 'c:\temp'
                    Write out 'Testing Function' to the c:\temp\LogTest.Log file in a CMTrace format, noting 'Test Script' as the component.
            .NOTES
                FileName:    Write-CCMLogEntry.ps1
                Author:      Cody Mathis, Adam Cook
                Contact:     @CodyMathis123, @codaamok
                Created:     2020-01-23
                Updated:     2020-01-23
        #>
        param (
            [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
            [Alias('Message', 'ToLog')]
            [string[]]$Value,
            [parameter(Mandatory = $false)]
            [ValidateSet(1, 2, 3)]
            [int]$Severity = 1,
            [parameter(Mandatory = $false)]
            [string]$Component,
            [parameter(Mandatory = $true)]
            [string]$FileName,
            [parameter(Mandatory = $true)]
            [string]$Folder,
            [parameter(Mandatory = $false)]
            [int]$Bias = (Get-CimInstance -Query "SELECT Bias FROM Win32_TimeZone").Bias,
            [parameter(Mandatory = $false)]
            [int]$MaxLogFileSize = 5MB,
            [parameter(Mandatory = $false)]
            [int]$LogsToKeep = 0
        )
        begin {
            # Determine log file location
            $LogFilePath = Join-Path -Path $Folder -ChildPath $FileName
    
            #region log rollover check if $MaxLogFileSize is greater than 0
            switch (([System.IO.FileInfo]$LogFilePath).Exists -and $MaxLogFileSize -gt 0) {
                $true {
                    #region rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
                    switch (([System.IO.FileInfo]$LogFilePath).Length -ge $MaxLogFileSize) {
                        $true {
                            # Get log file name without extension
                            $LogFileNameWithoutExt = $FileName -replace ([System.IO.Path]::GetExtension($FileName))
    
                            # Get already rolled over logs
                            $AllLogs = Get-ChildItem -Path $Folder -Name "$($LogFileNameWithoutExt)_*" -File
    
                            # Sort them numerically (so the oldest is first in the list)
                            $AllLogs = Sort-Object -InputObject $AllLogs -Descending -Property { $_ -replace '_\d+\.lo_$' }, { [int]($_ -replace '^.+\d_|\.lo_$') } -ErrorAction Ignore
    
                            foreach ($Log in $AllLogs) {
                                # Get log number
                                $LogFileNumber = [int][Regex]::Matches($Log, "_([0-9]+)\.lo_$").Groups[1].Value
                                switch (($LogFileNumber -eq $LogsToKeep) -and ($LogsToKeep -ne 0)) {
                                    $true {
                                        # Delete log if it breaches $LogsToKeep parameter value
                                        [System.IO.File]::Delete("$($Folder)\$($Log)")
                                    }
                                    $false {
                                        # Rename log to +1
                                        $NewFileName = $Log -replace "_([0-9]+)\.lo_$", "_$($LogFileNumber+1).lo_"
                                        [System.IO.File]::Copy("$($Folder)\$($Log)", "$($Folder)\$($NewFileName)", $true)
                                    }
                                }
                            }
    
                            # Copy main log to _1.lo_
                            [System.IO.File]::Copy($LogFilePath, "$($Folder)\$($LogFileNameWithoutExt)_1.lo_", $true)
    
                            # Blank the main log
                            $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, $false
                            $StreamWriter.Close()
                        }
                    }
                    #endregion rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
                }
            }
            #endregion log rollover check if $MaxLogFileSize is greater than 0
    
            # Construct date for log entry
            $Date = (Get-Date -Format 'MM-dd-yyyy')
    
            # Construct context for log entry
            $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        }
        process {
            foreach ($MSG in $Value) {
                #region construct time stamp for log entry based on $Bias and current time
                $Time = switch -regex ($Bias) {
                    '-' {
                        [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), $Bias)
                    }
                    Default {
                        [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), '+', $Bias)
                    }
                }
                #endregion construct time stamp for log entry based on $Bias and current time
    
                #region construct the log entry according to CMTrace format
                $LogText = [string]::Format('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">', $MSG, $Time, $Date, $Component, $Context, $Severity, $PID)
                #endregion construct the log entry according to CMTrace format
    
                #region add value to log file
                try {
                    $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, 'Append'
                    $StreamWriter.WriteLine($LogText)
                    $StreamWriter.Close()
                }
                catch [System.Exception] {
                    Write-Warning -Message "Unable to append log entry to $FileName file. Error message: $($_.Exception.Message)"
                }
                #endregion add value to log file
            }
        }
    }
    
    Function Test-ADUser {  
        [CmdletBinding()]  
        param(  
            [parameter(Mandatory = $true, position = 0)]  
            [string]$Username  
        )  
        Try {  
            Get-ADuser $Username -ErrorAction Stop  
            Return $true  
        }   
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {  
            Return $false  
        }  
    } 

    Function New-RandomPassword {
        Param(
            [Parameter(Mandatory = $false)]
            [ValidateRange(12,127)]
            [int]$MinimumPasswordLength,
            [Parameter(Mandatory = $false)]
            [ValidateRange(12,128)]
            [int]$MaximumPasswordLength,
            [Parameter(Mandatory = $true)]
            [ValidateRange(25,45)]
            [int]$NumberOfAlphaNumericCharacters,
            [Parameter()]
            [switch]$ConvertToSecureString,
            [Parameter()]
            [switch]$SCRIL
        )
        
        If ($MinimumPasswordLength -gt $MaximumPasswordLength) {
            $ErrorActionPreference = 'SilentlyContinue'
            Throw 'Minimum length cannot be greater than the maximum length.'
        }
        # DOES NOT WORK WITH POWERSHELL CORE
        Add-Type -AssemblyName 'System.Web'
        If ($SCRIL.IsPresent) {
            $length = '128'
        }
        Else {
            $length = Get-Random -Minimum $MinimumPasswordLength -Maximum $MaximumPasswordLength
        }
        $password = [System.Web.Security.Membership]::GeneratePassword($length,$NumberOfAlphaNumericCharacters)
        If ($ConvertToSecureString.IsPresent) {
            ConvertTo-SecureString -String $password -AsPlainText -Force
        } else {
            $password
        }
    }

    # Get the current timestamp for the log name
    $timestamp = Get-Date -Format o | ForEach-Object { $_ -replace ":", "." }
    # Set the log name
    $logName = "SCRIL-Rotation-$timestamp.log"
    $logDir = "C:\Windows\Logs\SCRIL"

    # Initialize the log
    Write-CCMLogEntry -Value '********************************' -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"
    Write-CCMLogEntry -Value 'Initializing Log...' -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"
    Write-CCMLogEntry -Value '********************************' -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"

    # Build the array
    Write-CCMLogEntry -Value 'Building an empty $userArray to store the SamAccountNames.' -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"
    $userArray = @()

    # Validate that the -User parameter is not empty
    If ($null -ne $User) {
        # Add the users to the array
        Write-CCMLogEntry -Value 'The User parameter is not $null. Adding account(s) to the array.' -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"
        ForEach ($usr in $user) {
            $userArray += $user
        }
    }
    Else {
        # Nothing to add
        Write-CCMLogEntry -Value 'The User parameter is $null. No action required.' -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"
    }

    # Validate that the -Group parameter is not empty
    If ($null -ne $Group) {
        # Loop through the group names provided
        Write-CCMLogEntry -Value 'The Group parameter is not $null. Looping through provided group(s).' -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"
        ForEach ($g in $Group) {
            # Validate that the group exists
            If (Get-ADGroup -Identity $g) {
                # Add the users from the group into the array
                Write-CCMLogEntry -Value "The security group $g exists; pulling the users and dropping them into the array." -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"
                $userArray += (Get-ADGroupMember -Recursive -Identity $g).SamAccountName
            }
            Else {
                # The provided group name does not exist
                Write-CCMLogEntry -Value "The security group $g does not exist. Please investigate names for errors." -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "3"
            }
        }
    }
    Else {
        # Nothing to add
        Write-CCMLogEntry -Value 'The Group parameter is $null. No action required.' -Component 'Initializing' -FileName $logName -Folder $logDir -Severity "1"
    }

    # Loop through the array
    ForEach ($u in $userArray) {
    # Test if the user exists
        If (!(Test-ADUser $u)) {
            Write-CCMLogEntry -Value "Error: $u does not exist!" -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "3"
        }
        Else {
            Write-CCMLogEntry -Value "$u is a valid account!" -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "1"
            # Test if the user has SCRIL enabled already
            If ((Get-ADUser -Identity $u -Server $server -Properties SmartCardLogonRequired).SmartCardLogonRequired -eq $false) {
                # SCRIL is not on
                Write-CCMLogEntry -Value "$u does not currently have SCRIL enforced." -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "2"
                # Cycle the password with a new random one (this should be able to to away when the Domain Functional level goes up)
                Write-CCMLogEntry -Value "Rotating the password for $u." -Component 'Rotate SCRIL' -File $logName -Folder $logDir -Severity '1'
                New-RandomPassword -NumberOfAlphaNumericCharacters 30 -SCRIL -ConvertToSecureString
                Set-ADAccountPassword -Identity $u -NewPassword (New-RandomPassword -NumberOfAlphaNumericCharacters 30 -SCRIL -ConvertToSecureString) –Reset -Server $Server
                Set-ADUser -Identity $u -ChangePasswordAtLogon $false -Server $Server -PasswordNeverExpires $true -CannotChangePassword $true
                # Enable SCRIL
                Write-CCMLogEntry -Value "Enabling SCRIL on $u." -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "1"
                Set-ADUser -Identity $u -Server $server -SmartcardLogonRequired:$true
                Write-CCMLogEntry -Value "Validating $u has SCRIL enforced..." -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "1"
                # Validate its enabled now
                If ((Get-ADUser -Identity $u -Server $server -Properties SmartCardLogonRequired).SmartCardLogonRequired -eq $true) {
                    # SCRIL is now enabled
                    Write-CCMLogEntry -Value "$u now has SCRIL enforced!" -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "1"
                }
                Else {
                    # SCRIL still $false; investigate why
                    Write-CCMLogEntry -Value "$u still does not have SCRIL enforced! Investigate the error." -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "3"
                }
            }
            Else {
                # SCRIL is on; rotate it
                Write-CCMLogEntry -Value "$u currently has SCRIL enforced. Rotating it..." -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "1"
                # Setting it to false
                Set-ADUser -Identity $u -Server $server -SmartcardLogonRequired:$false
                # Cycle the password with a new random one (this should be able to to away when the Domain Functional level goes up)
                Write-CCMLogEntry -Value "Rotating the password for $u." -Component 'Rotate SCRIL' -File $logName -Folder $logDir -Severity '1'
                New-RandomPassword -NumberOfAlphaNumericCharacters 30 -SCRIL -ConvertToSecureString
                Set-ADAccountPassword -Identity $u -NewPassword (New-RandomPassword -NumberOfAlphaNumericCharacters 30 -SCRIL -ConvertToSecureString) –Reset -Server $Server
                Set-ADUser -Identity $u -ChangePasswordAtLogon $false -Server $Server -PasswordNeverExpires $true -CannotChangePassword $true
                # Setting it back to true
                Set-ADUser -Identity $u -Server $server -SmartcardLogonRequired:$true
                # Validate its enabled, again
                If ((Get-ADUser -Identity $u -Server $server -Properties SmartCardLogonRequired).SmartCardLogonRequired -eq $true) {
                    # SCRIL is enabled
                    Write-CCMLogEntry -Value "SCRIL has been rotated for $u." -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "1"
                }
                Else {
                    # SCRIL still $false; investigate why
                    Write-CCMLogEntry -Value "$u does not have SCRIL enforced after rotation! Investigate the error." -Component 'Rotate SCRIL' -FileName $logName -Folder $logDir -Severity "3"
                }
            }
        }
    }

    # Close out the log
    Write-CCMLogEntry -Value '********************************' -Component 'Finalize' -FileName $logName -Folder $logDir -Severity "1"
    Write-CCMLogEntry -Value 'End Of Log' -Component 'Finalize' -FileName $logName -Folder $logDir -Severity "1"
    Write-CCMLogEntry -Value '********************************' -Component 'Finalize' -FileName $logName -Folder $logDir -Severity "1"

}