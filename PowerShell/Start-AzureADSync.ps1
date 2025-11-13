<#
.SYNOPSIS
    Function to initiate a full or delta sync for Azure AD.
    
.DESCRIPTION
    This function will invoke the command to perform a full (initial) or delta sync.

.EXAMPLE
    PS C:\> Start-AzureADSync -SyncServer AzureAD -Delta
    This exmaple invokes the Delta sync on the AzureAD server.

    PS C:\> Start-AzureADSync -SyncServer AzureAD -Full
    This example invokes the Full sync on the AzureAD server.

.INPUTS
    -SyncServer
        This parameter specifies the Azure AD connection server to kick the sync off on.

    -Delta
        This parameter specifies that we want to kick off a Delta sync.

    -Full
        This parameter specified that we want to kick off a Full (initial), sync.

    -Verbose
        This parameter will Write-Verbose comments. Self explanatory.
        
.OUTPUTS
    Verbose comments, if specified with -Verbose.

.NOTES
    Name:           Start-AzureADSync.ps1
    Author:         Ahnamataeus Vex
    Version:        1.0.0
    Release Date:   2020-12-23
#>
Function Start-AzureADSync {
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $False)]
        [string[]] 
        $SyncServer,
        [Parameter(mandatory = $True, ParameterSetName = 'Delta')]
        [switch] 
        $Delta,
        [Parameter(mandatory=$True, ParameterSetName = 'Full')]
        [switch] 
        $Full
    )

    Try {
        Test-Connection -ComputerName $SyncServer -Count 1 -ErrorAction Stop | Out-Null
        If ($Delta -eq $true) {
            Try {
            Invoke-Command -ComputerName $SyncServer -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Delta } -ErrorAction Stop
            Write-Output "Delta sync selected. Invoking a Delta sync on $SyncServer."
            }
            Catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
                Write-Warning "Access denied!"
            }
        }
        ElseIf ($Full -eq $true) {
            Try {
            Invoke-Command -ComputerName $SyncServer -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Initial } -ErrorAction Stop
            Write-Output "Full sync selected. Invoking a Full sync on $SyncServer."
            }
            Catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
                Write-Warning "Access denied!"
            }
        }
    }
    Catch [System.Net.NetworkInformation.PingException] {
        Write-Warning "The computer $(($SyncServer).ToUpper()) is offline or does not exist."
    }
}