Write-Host  -ForegroundColor Cyan "Starting Marshfield's Custom OSDCloud ..."
Start-Sleep -Seconds 1

#Prompt for BIOS Password
Write-Host  -ForegroundColor Cyan "Enter BIOS Password"
$passwd = Read-Host -AsSecureString 'Password'

#Make sure I have the latest OSD Content
#Write-Host  -ForegroundColor Cyan "Updating the awesome OSD PowerShell Module"
#Install-Module OSD -Force

#Write-Host  -ForegroundColor Cyan "Importing the sweet OSD PowerShell Module"
#Import-Module OSD -Force

#Start OSDCloud ZTI the RIGHT way
Write-Host  -ForegroundColor Cyan "Start OSDCloud with Marshfield Parameters"
Write-Host  -ForegroundColor Cyan "OSLanguage en-us OSBuild 20H2 OSEdition Education ZTI"
Start-OSDCloud -OSLanguage en-us -OSBuild 20H2 -OSEdition Education -ZTI

#Dell BIOS Config



#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 15 seconds!"
Start-Sleep -Seconds 15
wpeutil reboot