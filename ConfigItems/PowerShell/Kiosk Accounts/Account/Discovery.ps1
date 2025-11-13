# Discovery

# Detect if the kiosk account exists
If (Get-LocalUser -Name 'Kiosk' -ErrorAction SilentlyContinue) {
    $true
}
Else {
    $false
}