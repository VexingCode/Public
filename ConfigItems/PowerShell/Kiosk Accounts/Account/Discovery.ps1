# Discovery

# Detect if the kiosk account exists
If (Get-LocalUser -Name 'CoSKiosk' -ErrorAction SilentlyContinue) {
    $true
}
Else {
    $false
}