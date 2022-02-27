# Function to remove pinned items from the task bar

Function Start-UnpinFromTaskbar { 
    param( [string]$appname )
    
    Try {
        ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object {$_.Name -eq $appname}).Verbs() | Where-Object {$_.Name -like "Unpin from*"} | %{$_.DoIt()}
    } 
    Catch {
        $a="b"
        }
    }
    
    # Start-UnpinFromTaskbar -AppName "Mail"