$Pool = "SMS Distribution Points Pool"

((Get-IISServerManager).ApplicationPools | Where {$_.Name -eq $Pool}).GetAttributeValue("queueLength")
