$Pool = "CCM Client Notification Proxy Pool"
$PoolSize = 30000

((Get-IISServerManager).ApplicationPools | Where {$_.Name -eq $Pool}).SetAttributeValue("queueLength",$PoolSize)