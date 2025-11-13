$Pool = "WsusPool"
$Size = 0

((Get-IISServerManager).ApplicationPools | Where {$_.Name -eq $Pool}).SetAttributeValue("recycling.periodicrestart.privateMemory",$Size)