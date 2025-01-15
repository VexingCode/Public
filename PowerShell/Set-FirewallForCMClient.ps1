# Enable Firewall for ConfigMgr Client

# Inbound: Windows Management Instrumentation (WMI)
Get-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" -Direction Inbound | Set-NetFirewallRule -Enabled True -Direction Inbound -Description 'ConfigMgr'

# Inbound: File and Printer Sharing (Group)
Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Direction Inbound | Set-NetFirewallRule -Enabled True -Direction Inbound -Description 'ConfigMgr'

# Inbound: Remote Control
New-NetFirewallRule -Direction Inbound -InterfaceType Any -Name "CM-Remote-Control-TCP-In" -Protocol TCP -LocalPort 2701 -Profile Domain,Private -Program 'C:\WINDOWS\CCM\RemCtrl\CmRcService.exe' -DisplayName 'ConfigMgr Remote Control' -Description 'Port exclusion for the ConfigMgr Remote Control tool.' -Group 'ConfigMgr'

# Outbound: File and Printer Sharing (Group)
Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Direction Outbound | Set-NetFirewallRule -Enabled True -Direction Outbound -Description 'ConfigMgr'

# Outbound: HTTP Communication
New-NetFirewallRule -Direction Outbound -InterfaceType Any -Protocol TCP -RemotePort 80,8530 -DisplayName "HTTP Communication" -Group 'ConfigMgr'

# Outbound: HTTPS Communication
New-NetFirewallRule -Direction Outbound -InterfaceType Any -Protocol TCP -RemotePort 443,8531 -DisplayName "HTTPS Communication" -Group 'ConfigMgr'

# Outbound: Network Access Point UDP
New-NetFirewallRule -Direction Outbound -InterfaceType Any -Protocol UDP -RemotePort 67,68,25536,9 -DisplayName "Network Access Point UDP Ports" -Group 'ConfigMgr'

# Outbound: Client Notification TCP
New-NetFirewallRule -Direction Outbound -InterfaceType Any -Protocol TCP -RemotePort 10123 -DisplayName "Client Notification TCP Port" -Group 'ConfigMgr'