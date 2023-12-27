# This script disables the pop up of password reminder - "Windows needs your current credentials"
# Can be deployed via MDM, or locally installed with admin privileges
# Function to write script log to a file, contains time stamp for better visibility 
$Logfile = "PATHtoFILE\fix_win_popup_logon_reminder.log"
function WriteLog
{
	Param ([string]$LogString)
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$LogMessage = "$Stamp $LogString"
	Add-content $LogFile -value $LogMessage -Force
}

# Registry path of the notification
$registryPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.Explorer.Notification.{579F4729-1ECF-6F8C-AE55-8198BB56AE33}'
$valueName = 'Enabled'  # Replace with your desired value name
# Check if the registry path exists
if (Test-Path $registryPath) {
    WriteLog("Registry path exists.")
    New-ItemProperty -Path $registryPath -Name $valueName -Value 0 -PropertyType DWORD -Force | Out-Null
} else {
    WriteLog("Registry path doesn't exist so no need to create, exiting.")
    Exit 0
}
# Check if the DWORD value exists
$reg_properties = Get-ItemProperty -Path $registryPath
if ($reg_properties.Enabled -eq 0) {
    
    WriteLog("DWORD value created successfully.")
    Exit 0

} else {
    WriteLog("DWORD value wasn't created successfully.")
    Exit 1
}