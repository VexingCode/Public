if ((Get-Service -Name RemoteRegistry).Status -ne "Running" -or (Get-Service -Name RemoteRegistry).StartType -ne "Automatic")
{
	$false
}
else
{
	$true
}
