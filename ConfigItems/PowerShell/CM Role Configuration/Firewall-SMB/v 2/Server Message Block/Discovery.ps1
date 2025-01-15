$NewNetFirewallRule = @{
    DisplayName = "ConfigMgr: Server Message Block (SMB)"
    LocalPort = 445
    Direction="Inbound"
    Protocol ="TCP" 
    Action = "Allow"
    Group = "System Center Configuration Manager"
}

$NewNetFirewallRule.DisplayName = $NewNetFirewallRule.DisplayName +" ("+$NewNetFirewallRule.Protocol+" "+$NewNetFirewallRule.LocalPort+")"
$FindRule = Get-NetFirewallRule | Where {$_.DisplayName -eq $NewNetFirewallRule.DisplayName}

If (-not $FindRule)
{
    Return $false
}

If (-not ($FindRule.Enabled -eq $true))
{
    Return $false
}

Return $true