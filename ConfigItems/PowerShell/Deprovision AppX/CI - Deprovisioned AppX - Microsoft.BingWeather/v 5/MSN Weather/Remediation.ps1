Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.BingWeather'} | Remove-AppxProvisionedPackage -Online -AllUsers