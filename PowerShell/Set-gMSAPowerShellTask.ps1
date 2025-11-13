# Add parameters so its more agnostic to the account, triggers, and script

Function Set-gMSAPowerShellTask {
    $action = New-ScheduledTaskAction "powershell" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\SCRIL\Reset-SCRIL.ps1 -Group 'SECGrp1-All','SECGrp2-All' -Server 'AD'"
    $trigger = New-ScheduledTaskTrigger -At 01:00 -Daily
    $principal = New-ScheduledTaskPrincipal -UserId Domain\SCRILgMSA$ -LogonType Password
    Register-ScheduledTask 'Rotate SCRIL Credentials' -Action $action -Trigger $trigger -Principal $principal
}