[console]::WindowWidth=120
[console]::WindowHeight=50
[console]::BufferWidth=[console]::WindowWidth

Write-Host  -ForegroundColor Cyan "Starting Marshfield's Custom OSDCloud ..."
Start-Sleep -Seconds 1

#Prompt for BIOS Password
Write-Host  -ForegroundColor Cyan "Enter BIOS Password"
$passwd = Read-Host -AsSecureString 'Password'

#Dell BIOS Config
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cattanach-mfld/osdzti/main/DellConfigure.zip" -OutFile "X:\OSDCloud\DellConfigure.zip"
Expand-Archive "X:\OSDCloud\DellConfigure.zip" "X:\OSDCloud"

$password = ((New-Object System.Management.Automation.PSCredential('dummy',$passwd)).GetNetworkCredential().Password)

& "X:\OSDCloud\DellConfigure\cctk.exe" --setuppwd=$password
& "X:\OSDCloud\DellConfigure\cctk.exe" -i "X:\OSDCloud\DellConfigure\multiplatform_201906070913.cctk" --valsetuppwd=$password

#Make sure I have the latest OSD Content
#Write-Host  -ForegroundColor Cyan "Updating the awesome OSD PowerShell Module"
#Install-Module OSD -Force

#Write-Host  -ForegroundColor Cyan "Importing the sweet OSD PowerShell Module"
#Import-Module OSD -Force

#Start OSDCloud ZTI the RIGHT way
Write-Host  -ForegroundColor Cyan "Start OSDCloud with Marshfield Parameters"
Write-Host  -ForegroundColor Cyan "OSLanguage en-us OSBuild 21H1 OSEdition Education ZTI"
Start-OSDCloud -OSLanguage en-us -OSBuild 21H2 -OSEdition Education -ZTI

#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 15 seconds!"
Start-Sleep -Seconds 15
wpeutil reboot
