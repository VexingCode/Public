Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.SkypeApp'} | Remove-AppxProvisionedPackage -Online -AllUsers