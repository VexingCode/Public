# This is the meat and potatoes of the Win32 app used to set the device type for HAADJ machines being AutoPiloted.
# The below is copy/pasted into the PowerShell App Deployment Toolkit, which we use to deploy scripts as Win32.

# Grab the user that kicked off the AutoPilot OOBE; in this instance we use special DEM accounts for this
$User = (Get-ChildItem HKLM:\software\Microsoft\Enrollments | Where-Object {$_.property -eq 'UPN'} | Get-ItemProperty).UPN

# Get the current date time (as the computer understands it)
$DateTime = Get-Date

# Create the registry key for CompanyName, if not present already
If (!(Test-Path HKLM:\SOFTWARE\CompanyName)) {
    New-Item HKLM:\SOFTWARE\CompanyName -Force
}

# Set the Properties for AutoPilot=True and Time
New-ItemProperty HKLM:\Software\CompanyName -Name SMSOSD-AutoPilot -PropertyType String -Value "True" -Force
New-ItemProperty HKLM:\Software\CompanyName -Name SMSOSD-Time -PropertyType String -Value $DateTime.ToString() -Force

# Based on the DEM account used to kick off the AutoPilot, we determine a build
# These regex queries will break if we reach double digits on the numbers (\d would need to be \d\d))

# Standard Workstation
If ($user -eq 'APStandard@domain.com' -or $user -match 'APStandard\d@domain.com') {
    New-ItemProperty HKLM:\Software\CompanyName -Name SMSOSD-Type -PropertyType String -Value "STD" -Force
    New-ItemProperty HKLM:\Software\CompanyName -Name SMSOSD-User -PropertyType String -Value $user -Force
}
# Kiosk Workstation
ElseIf ($user -eq 'APKiosk@domain.com' -or $user -match 'APKiosk\d@domain.com') {
    New-ItemProperty HKLM:\Software\CompanyName -Name SMSOSD-Type -PropertyType String -Value "KSK" -Force
    New-ItemProperty HKLM:\Software\CompanyName -Name SMSOSD-User -PropertyType String -Value $user -Force
}
# Laptop
ElseIf ($user -eq 'APLaptop@domain.com' -or $user -match 'APLaptop\d@domain.com') {
    New-ItemProperty HKLM:\Software\CompanyName -Name SMSOSD-Type -PropertyType String -Value "LPTP" -Force
    New-ItemProperty HKLM:\Software\CompanyName -Name SMSOSD-User -PropertyType String -Value $user -Force
}