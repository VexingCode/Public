$NewNetFirewallRule = @{
    DisplayName = "ConfigMgr: WSUS HTTP"
    LocalPort = 8530
    Direction="Inbound"
    Protocol ="TCP" 
    Action = "Allow"
    Group = "System Center Configuration Manager"
}

$NewNetFirewallRule.DisplayName = $NewNetFirewallRule.DisplayName +" ("+$NewNetFirewallRule.Protocol+" "+$NewNetFirewallRule.LocalPort+")"
$FindRule = Get-NetFirewallRule | Where {$_.DisplayName -eq $NewNetFirewallRule.DisplayName}

If (-not $FindRule)
{
    New-NetFirewallRule @NewNetFirewallRule
}

If (-not ($FindRule.Enabled -eq $true))
{
    Enable-NetFirewallRule -DisplayName $NewNetFirewallRule.DisplayName
}
