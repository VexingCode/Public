If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.WindowsCommunicationsApps'}) {
$true }
Else {
$false
}