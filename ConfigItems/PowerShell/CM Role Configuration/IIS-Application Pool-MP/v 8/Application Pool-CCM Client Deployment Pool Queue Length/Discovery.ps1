$Pool = "CCM Client Deployment Pool"

((Get-IISServerManager).ApplicationPools | Where {$_.Name -eq $Pool}).GetAttributeValue("queueLength")