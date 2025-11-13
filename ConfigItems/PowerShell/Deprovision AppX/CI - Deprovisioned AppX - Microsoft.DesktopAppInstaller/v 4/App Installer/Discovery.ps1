If (Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match 'Microsoft.DesktopAppInstaller'}) {
$true }
Else {
$false
}