# Log some variables
$Directory = "$PSScriptRoot\LegacyBackup-GPO"
$Domain = (Get-ADDomainController).Domain
$DC = (Get-ADDomainController).Hostname

# List of characters to remove explicitly from display names
$invalidChars = @('[', ']', '(', ')', ',', ';', ':', '+', '!', ' ')

# Create the regex pattern by joining characters with pipe (|) and escaping them
$escapedChars = $invalidChars | ForEach-Object { [RegEx]::Escape($_) }
$pattern = '({0})' -f ($escapedChars -join '|')

# Get all teh GPOs
$GPOs = Get-GPO -All -Domain $Domain -Server $DC

# Create the directory if it doesn't exist
If (!(Test-Path $Directory)) {
    New-Item $Directory -ItemType Directory | Out-Null
}

# Loop through each of the GPOs and back them up
ForEach ($GPO in $GPOs) {
    # Remove invalid characters in the DisplayName
    $Name = $GPO.DisplayName -replace $pattern, ''

    # Trim the result to ensure no leading or trailing spaces
    $Name = $Name.Trim()

    # Generate folder name based on the cleaned policy name and GPO GUID
    $GUID = $GPO.Id
    $DirName = "$Directory\$Name-{$GUID}"

    # Create a folder for the GPO, if one does not exist
    If (!(Test-Path $DirName)) {
        New-Item $DirName -ItemType Directory | Out-Null
    }

    # Backup the policy
    Write-Host "Performing backup operation on $($GPO.DisplayName)."
    Try {
        $GPOBackup = $GPOBackup = Backup-GPO -Name $GPO.DisplayName -Domain $Domain -Server $DC -Path $Directory -ErrorAction SilentlyContinue
    } Catch {
        Write-Host "Error while backing up $GPO."
        Write-Host $Error[0].Exception.Message
        continue
    }
    $GpoBackupId = $GPOBackup.ID.Guid
    $BackupIdDir = $Directory + "\" + "{"+ $GpoBackupId + "}"

    # Execute the Robocopy command and redirect output to null
    robocopy $BackupIdDir $DirName /E /IS /IT | Out-Null

    # Remove the Backup Id ($BackupIdDir) folder
    Try {
        Remove-Item -Path $BackupIdDir -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    } Catch {
        Write-Host "Error while deleting directory: $BackupIdDir"
        Write-Host $Error[0].Exception.Message
        continue
    }
}