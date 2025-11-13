# Remediation

# Set the variables

# Specify the path, and its recursive folders, that you want to search
# Since we are using -Recurse, so you do not need to wildcard the Path unless your wildcard is in the beginning/middle
$path = ''

# Specify the file type in the filter; preface with a wildcard
$filter = ''

# Specify the name of the file you are looking for, with extension; use wildcards if you aren't sure
$name = ''

# Get the files you want removed
$files = Get-ChildItem -Path $path -Filter $filter -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -like $name}

# Loop through the files and nuke them
ForEach ($file in $files) {
    Remove-Item -Path $file.FullName
}