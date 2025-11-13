Function Delete-CitrixIcons {

    # Delete Citrix icons
    $shellObj = New-Object -ComObject WScript.Shell
    $shortcuts = Get-ChildItem -Path "C:\Users\*\Desktop\" -recurse | Where-Object {$_.Extension -eq ".lnk" }
    foreach ($s in $shortcuts)
    {
        if(($shellObj.CreateShortcut($s).TargetPath) -like "C:\Program Files (x86)\Citrix\ICA Client\*")
        {
            Write-Host "Found a target | $s" -ForegroundColor Red 
            # Delete it
            Remove-Item $s
        }

    }
    # Delete blank folders
    $Paths = "C:\Users\*\Desktop\"
    foreach($childItem in (Get-ChildItem $Paths -Recurse | Where-Object {$_.PSIsContainer -eq $True} | Where-Object {$_.GetFiles().Count -eq 0}))
    {
        # if it's a folder AND does not have child items of its own
        if( ($childItem.PSIsContainer) -and (!(Get-ChildItem -Recurse -Path $childItem.FullName)))
        {
            # Delete it        
            Remove-Item $childItem.FullName -Confirm:$false
        }
    }
}