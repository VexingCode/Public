Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.XboxApp'} | Remove-AppxProvisionedPackage -Online -AllUsers