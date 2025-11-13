# Detection

# Assume compliance is $false
$compliant = $false

# Set the variables

# Specify the path, and its recursive folders, that you want to search
# Since we are using -Recurse, so you do not need to wildcard the Path unless your wildcard is in the beginning/middle
$path = ''

# Specify the file type in the filter; preface with a wildcard
$filter = ''

# Specify the name of the file you are looking for, with extension; use wildcards if you aren't sure
$name = ''

# Detect if the icons are found anywhere in the folder specified
If (Get-ChildItem -Path $path -Filter $filter -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -like $name}) {
    # File(s) found; return $true for NonCompliant
    $compliant = $true
} Else {
    # File(s) not found; return $false for Compliant
    $compliant = $false
}

$compliant