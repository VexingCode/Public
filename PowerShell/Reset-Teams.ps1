<#
.SYNOPSIS
    Kill Teams, clear the cache, and restart Teams.
.DESCRIPTION
    Kill Teams, clear the cache, and restart Teams. This can help resolve issues you may have
    with the Teams client, and can be a first step before doing a full reinstall.
.EXAMPLE
    PS C:\Windows\System32> Reset-Teams
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Name:           Reset-Teams.ps1
    Author:         Ahnamataeus Vex
    Contributor:    Jóhannes Geir Kristjánsson
    Version:        1.0.0
    Release Date:   2022-03-31
    To-do:
        Add capability to run against remote machine
#>

Function Reset-Teams {
    # First, kill the Teams client, and give it a few seconds to complete
    Get-Process Teams | Stop-Process -Force
    Start-Sleep -Seconds 2

    # Clear the Teams' Cache; sleep for a few seconds again
    Get-ChildItem "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Teams\*" -Directory | Where-Object Name -In ('Application Cache','Blob Storage','Databases','GPUCache','IndexedDB','Local Storage','tmp') | ForEach-Object {Remove-Item $_.FullName -Recurse -Force}
    Start-Sleep -Seconds 2

    # Start the Squirrel Updater to launch Teams
    Start-Process "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Teams\Update.exe" -ArgumentList '--processStart "Teams.exe"'
}