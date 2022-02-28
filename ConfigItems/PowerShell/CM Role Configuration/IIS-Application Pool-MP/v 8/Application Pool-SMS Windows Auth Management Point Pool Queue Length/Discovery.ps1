$Pool = "SMS Windows Auth Management Point Pool"

((Get-IISServerManager).ApplicationPools | Where {$_.Name -eq $Pool}).GetAttributeValue("queueLength")