Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.MicrosoftStickyNotes'} | Remove-AppxProvisionedPackage -Online -AllUsers