$NewNetFirewallRule = @{
    DisplayName = "ConfigMgr: PXE DHCP/TFTP"
    LocalPort = "67-69"
    Direction="Inbound"
    Protocol ="UDP" 
    Action = "Allow"
    Group = "System Center Configuration Manager"
}

$NewNetFirewallRule.DisplayName = $NewNetFirewallRule.DisplayName +" ("+$NewNetFirewallRule.Protocol+" "+$NewNetFirewallRule.LocalPort+")"
$FindRule = Get-NetFirewallRule | Where {$_.DisplayName -eq $NewNetFirewallRule.DisplayName}

If (-not $FindRule)
{
    Return $False
}

If (-not ($FindRule.Enabled -eq $true))
{
    Return $False
}

Return $True