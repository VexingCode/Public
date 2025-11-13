If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.Getstarted'}) {
$true }
Else {
$false
}