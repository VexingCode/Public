(Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name='Default Web Site']/logFile" -name "period")