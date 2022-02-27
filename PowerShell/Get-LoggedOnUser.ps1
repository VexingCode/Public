<#

		Description: Grabs logged on users by querying processes, 
        who is running them, and excluding service/system accounts.

		Inputs: Workstation name.

		Outputs: Currently logged in users, including remote users.

		Example: Get-LoggedOnUser ComputerName

#>

Function Get-LoggedOnUser { 
    [CmdletBinding()]             
     Param              
       (                        
        [Parameter(Mandatory=$true, 
                   Position=0,                           
                   ValueFromPipeline=$true,             
                   ValueFromPipelineByPropertyName=$true)]             
        [String[]]$ComputerName 
       ) #End Param 
     
    Begin             
    {             
        Write-Host "`n Checking Users . . . " 
        $i = 0             
    } #Begin           
    Process             
    { 
        $ComputerName | Foreach-object { 
        $Computer = $_ 
        Try 
            { 
                $processinfo = @(Get-WmiObject -class win32_process -ComputerName $Computer -EA "Stop") 
                    If ($processinfo) 
                    {     
                        $processinfo | Foreach-Object {$_.GetOwner().User} |  
                        Where-Object {$_ -ne "NETWORK SERVICE" -and $_ -ne "LOCAL SERVICE" -and $_ -ne "SYSTEM"} | 
                        Sort-Object -Unique | 
                        ForEach-Object { New-Object psobject -Property @{Computer=$Computer;LoggedOn=$_} } |  
                        Select-Object Computer,LoggedOn 
                    } #If 
            } 
        Catch 
            { 
                "Cannot find any processes running on $computer" | Out-Host 
            } 
         } #Forech-object(Comptuters)        
                 
     }#Process 
    End 
    { 
     
    } #End 
     
}