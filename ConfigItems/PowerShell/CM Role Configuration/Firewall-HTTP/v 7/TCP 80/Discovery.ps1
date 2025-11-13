$NewNetFirewallRule = @{
    DisplayName = "ConfigMgr: HTTP"
    LocalPort = 80
    Direction="Inbound"
    Protocol ="TCP" 
    Action = "Allow"
    Group = "System Center Configuration Manager"
}

$NewNetFirewallRule.DisplayName = $NewNetFirewallRule.DisplayName +" ("+$NewNetFirewallRule.Protocol+" "+$NewNetFirewallRule.LocalPort+")"
$FindRule = Get-NetFirewallRule | Where {$_.DisplayName -eq $NewNetFirewallRule.DisplayName}

If (-not $FindRule)
{
    return $false
}

If (-not ($FindRule.Enabled -eq $true))
{
    return $false
}

return $true