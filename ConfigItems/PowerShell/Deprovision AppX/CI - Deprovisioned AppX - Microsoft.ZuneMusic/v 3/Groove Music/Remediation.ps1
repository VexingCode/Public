Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.ZuneMusic'} | Remove-AppxProvisionedPackage -Online -AllUsers