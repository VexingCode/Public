Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.WebMediaExtensions'} | Remove-AppxProvisionedPackage -Online -AllUsers