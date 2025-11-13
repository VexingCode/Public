$Pool = "WsusPool"

((Get-IISServerManager).ApplicationPools | Where {$_.Name -eq $Pool}).GetAttributeValue("queueLength")