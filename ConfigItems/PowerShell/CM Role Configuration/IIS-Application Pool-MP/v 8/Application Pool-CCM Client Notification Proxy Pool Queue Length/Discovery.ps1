$Pool = "CCM Client Notification Proxy Pool"

((Get-IISServerManager).ApplicationPools | Where {$_.Name -eq $Pool}).GetAttributeValue("queueLength")