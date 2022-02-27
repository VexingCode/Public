$arr=@("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9")
ForEach ($n in $arr){
    Write-Output "Checking number of files with name $n*.*"
    $count=(Get-ChildItem "C:\Program Files\Microsoft Configuration Manager\inboxes\auth\statesys.box\incoming\Backup"  –Filter "$n*.*" | Where-Object { !$_.PsIsContainer } ).Count
    If ($count -ne 0){
        Write-Output "Moving $count files named $n*.* to incoming"
        Get-ChildItem "C:\Program Files\Microsoft Configuration Manager\inboxes\auth\statesys.box\incoming\Backup" -Filter "$n*.*" | Move-Item -Force -Destination "C:\Program Files\Microsoft Configuration Manager\inboxes\auth\statesys.box\incoming" -Verbose
        Write-Output "Sleeping for 5 minutes to allow CM to catch up."
        Start-Sleep 300
    }
}