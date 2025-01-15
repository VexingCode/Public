If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.StorePurchaseApp'}) {
$true }
Else {
$false
}