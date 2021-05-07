Write-Host  -ForegroundColor Cyan "Starting Marshfield's Custom OSDCloud ..."
Start-Sleep -Seconds 1

#Make sure I have the latest OSD Content
#Write-Host  -ForegroundColor Cyan "Updating the awesome OSD PowerShell Module"
#Install-Module OSD -Force

#Write-Host  -ForegroundColor Cyan "Importing the sweet OSD PowerShell Module"
#Import-Module OSD -Force

#Set Dell BIOS
Function Get-DellBIOSProvider
{
    [CmdletBinding()]
    param()		
	If (!(Get-Module DellBIOSProvider -listavailable)) 
		{
			Install-Module DellBIOSProvider -ErrorAction SilentlyContinue
			Write_Log -Message_Type "INFO" -Message "DellBIOSProvider has been installed"  			
		}
	Else
		{
			Import-Module DellBIOSProvider -ErrorAction SilentlyContinue
			Write_Log -Message_Type "INFO" -Message "DellBIOSProvider has been imported"  			
		}
}

Get-DellBIOSProvider 
  
$IsPasswordSet = (Get-Item -Path DellSmbios:\Security\IsAdminPasswordSet).currentvalue 

If($IsPasswordSet -eq $false) {
    $passwd = Read-Host -AsSecureString 'Enter BIOS Password'
    & Set-Item -Path Dellsmbios:\Security\AdminPassword -Value ((New-Object System.Management.Automation.PSCredential('dummy',$passwd)).GetNetworkCredential().Password)     

    $settingsList = @() # Create the empty array that will eventually be the CSV file

    $row = New-Object System.Object # Create an object to append to the array
    $row | Add-Member -MemberType NoteProperty -Name "Setting" -Value "AdminSetupLockout"
    $row | Add-Member -MemberType NoteProperty -Name "Value" -Value "Enabled"
    $settingsList += $row
    $row = New-Object System.Object # Create an object to append to the array
    $row | Add-Member -MemberType NoteProperty -Name "Setting" -Value "LegacyOrom"
    $row | Add-Member -MemberType NoteProperty -Name "Value" -Value "Disabled"
    $settingsList += $row
    $row = New-Object System.Object # Create an object to append to the array
    $row | Add-Member -MemberType NoteProperty -Name "Setting" -Value "UefiBootPathSecurity"
    $row | Add-Member -MemberType NoteProperty -Name "Value" -Value "AlwaysExceptInternalHdd"
    $settingsList += $row

    $Dell_BIOS = get-childitem -path DellSmbios:\ | foreach {
        get-childitem -path @("DellSmbios:\" + $_.Category)  | select-object attribute, currentvalue, possiblevalues, PSChildName}   
        
    foreach ($New_Setting in $settingsList) { 
        $Setting_To_Set = $New_Setting.Setting 
        $Setting_NewValue_To_Set = $New_Setting.Value 
        
        ForEach($Current_Setting in $Dell_BIOS | Where {$_.attribute -eq $Setting_To_Set}) { 
            $Attribute = $Current_Setting.attribute
            $Setting_Cat = $Current_Setting.PSChildName
            $Setting_Current_Value = $Current_Setting.CurrentValue

            Try {
                & Set-Item -Path Dellsmbios:\$Setting_Cat\$Attribute -Value $Setting_NewValue_To_Set -Password ((New-Object System.Management.Automation.PSCredential('dummy',$passwd)).GetNetworkCredential().Password)						
            }
            Catch {
                Write-Host "ERROR1 - Can not change setting $Attribute (Return code $Change_Return_Code)"  																		
            }
        }  
    }  
}






#Start OSDCloud ZTI the RIGHT way
Write-Host  -ForegroundColor Cyan "Start OSDCloud with Marshfield Parameters"
Write-Host  -ForegroundColor Cyan "OSLanguage en-us OSBuild 20H2 OSEdition Education ZTI"
Start-OSDCloud -OSLanguage en-us -OSBuild 20H2 -OSEdition Education -ZTI


#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 15 seconds!"
Start-Sleep -Seconds 15
wpeutil reboot