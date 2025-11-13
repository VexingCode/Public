# Detection

# Assume compliance is $true
$compliant = $true

# Specify the file you are looking for
$path = 'C:\Users\*\AppData\Local\Microsoft\Teams\current\Teams.exe'

# Detect if the file(s) are found anywhere in the folder specified
If (Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue) {
    # File(s) found; return $false for NonCompliant
    $compliant = $false
} Else {
    # File(s) not found; return $true for Compliant
    $compliant = $true
}

$compliant
