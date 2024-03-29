Write-Host -ForegroundColor Cyan "Starting Marshfield's Custom OSDCloud ..."


##########################################################################
###################### SET DELL BIOS PASS ################################
##########################################################################

if ((Get-MyComputerManufacturer -Brief) -eq "Dell") {
    if (Get-Volume.usb) {
        $drives = (Get-Volume.usb).DriveLetter
        foreach ($drive in $drives) {
            if (Test-Path ($drive + ":\BiosPassword.txt")) {
                $passwd = ConvertTo-SecureString (Get-Content ($drive + ":\BiosPassword.txt")) -AsPlainText -Force
                $password = ((New-Object System.Management.Automation.PSCredential('dummy',$passwd)).GetNetworkCredential().Password)
                Break
            }
        }
    }
}

##########################################################################
###################### END DELL BIOS PASS ################################
##########################################################################

#$mfldwinver = "Windows 11"
#$reply = Read-Host "Shared Device?[y/n]"
#if ( $reply -match "[yY]" ) { 
    #$mfldwinver = "Windows 10"
#    $wimUrl = 'https://wim.marshfieldschools.org/install_21H1-1-Windows-10-Education.wim'
#} else {
    #$mfldwinver = "Windows 11"
    $wimUrl = 'https://wim.marshfieldschools.org/Windows11_22H2_EDU.wim'
#}

#Remove the USB Drive so that it can reboot properly
if (Get-Volume.usb) {
    Write-Warning "Press Remove Flash Drive"
    while (Get-Volume.usb) {
        Start-Sleep -Seconds 2
    }
}


##########################################################################
###################### SET DELL BIOS INFO ################################
##########################################################################

if ((Get-MyComputerManufacturer -Brief) -eq "Dell") {
    if (!($passwd)) {
        do {
            #Prompt for BIOS Password
            Write-Host -ForegroundColor Cyan "Enter BIOS Password"
            $passwd = Read-Host -AsSecureString 'Password'
            $password = ((New-Object System.Management.Automation.PSCredential('dummy',$passwd)).GetNetworkCredential().Password)

            Write-Host -ForegroundColor Cyan "Enter BIOS Password Again"
            $passwd2 = Read-Host -AsSecureString 'Password'
            $password2 = ((New-Object System.Management.Automation.PSCredential('dummy',$passwd2)).GetNetworkCredential().Password)

            if ($password -ne $password2) {
                Write-Host -ForegroundColor Yellow "Passwords Do Not Match!"
            }
        } until ($password -eq $password2) 
    }

    #Dell BIOS Config
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cattanach-mfld/osdzti/main/DellConfigure.zip" -OutFile "X:\OSDCloud\DellConfigure.zip"
    Expand-Archive "X:\OSDCloud\DellConfigure.zip" "X:\OSDCloud"

    & "X:\OSDCloud\DellConfigure\cctk.exe" --setuppwd=$password
    & "X:\OSDCloud\DellConfigure\cctk.exe" -i "X:\OSDCloud\DellConfigure\multiplatform_201906070913.cctk" --valsetuppwd=$password
}

##########################################################################
###################### END DELL BIOS INFO ################################
##########################################################################
























function Start-OSDCloudMFLD {
#function Start-OSDCloud {
    <#
    .SYNOPSIS
    Starts the OSDCloud Windows 10 or 11 Build Process from the OSD Module or a GitHub Repository

    .DESCRIPTION
    Starts the OSDCloud Windows 10 or 11 Build Process from the OSD Module or a GitHub Repository

    .LINK
    https://github.com/OSDeploy/OSD/tree/master/Docs
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        #Automatically populated from Get-MyComputerManufacturer -Brief
        [System.String]
        $Manufacturer = (Get-MyComputerManufacturer -Brief),
        
        #Automatically populated from Get-MyComputerProduct
        [System.String]
        $Product = (Get-MyComputerProduct),

        #$Global:StartOSDCloud.MSCatalogFirmware = $true
        [System.Management.Automation.SwitchParameter]
        $Firmware,

        #Restart the computer after Invoke-OSDCloud to OOBE
        [System.Management.Automation.SwitchParameter]
        $Restart,

        #Shutdown the computer after Invoke-OSDCloud
        [System.Management.Automation.SwitchParameter]
        $Shutdown,
        
        #Captures screenshots during OSDCloud WinPE
        [System.Management.Automation.SwitchParameter]
        $Screenshot,
        
        #Skips the Autopilot Task routine
        [System.Management.Automation.SwitchParameter]
        $SkipAutopilot,
        
        #Skips the ODT Task routine
        [System.Management.Automation.SwitchParameter]
        $SkipODT,
        
        #Skip prompting to wipe Disks
        [System.Management.Automation.SwitchParameter]
        $ZTI,

        #Operating System Version of the Windows installation
        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('Windows 11','Windows 10')]
        [System.String]
        $OSVersion,

        #Operating System Build of the Windows installation
        #Alias = Build
        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('21H2','21H1','20H2','2004','1909','1903','1809')]
        [Alias('Build')]
        [System.String]
        $OSBuild,

        #Operating System Edition of the Windows installation
        #Alias = Edition
        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('Home','Home N','Home Single Language','Education','Education N','Enterprise','Enterprise N','Pro','Pro N')]
        [Alias('Edition')]
        [System.String]
        $OSEdition,

        #Operating System Language of the Windows installation
        #Alias = Culture, OSCulture
        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet (
            'ar-sa','bg-bg','cs-cz','da-dk','de-de','el-gr',
            'en-gb','en-us','es-es','es-mx','et-ee','fi-fi',
            'fr-ca','fr-fr','he-il','hr-hr','hu-hu','it-it',
            'ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl',
            'pl-pl','pt-br','pt-pt','ro-ro','ru-ru','sk-sk',
            'sl-si','sr-latn-rs','sv-se','th-th','tr-tr',
            'uk-ua','zh-cn','zh-tw'
        )]
        [Alias('Culture','OSCulture')]
        [System.String]
        $OSLanguage,

        #License of the Windows Operating System
        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('Retail','Volume')]
        [System.String]
        $OSLicense,

        #Searches for the specified WIM file
        [Parameter(ParameterSetName = 'CustomImage')]
        [System.Management.Automation.SwitchParameter]
        $FindImageFile,

        #Downloads a WIM file specified by the URK
        [Parameter(ParameterSetName = 'CustomImage')]
        [System.String]
        $ImageFileUrl,

        #Images using the specified Image Index
        [Parameter(ParameterSetName = 'CustomImage')]
        [System.String]
        $ImageIndex = 'AUTO'
    )
    #=================================================
    #	$Global:StartOSDCloud
    #=================================================
    $Global:StartOSDCloud = $null
    $Global:StartOSDCloud = [ordered]@{
        AutopilotJsonChildItem = $null
        AutopilotJsonItem = $null
        AutopilotJsonName = $null
        AutopilotJsonObject = $null
        AutopilotOOBEJsonChildItem = $null
        AutopilotOOBEJsonItem = $null
        AutopilotOOBEJsonName = $null
        AutopilotOOBEJsonObject = $null
        Function = $MyInvocation.MyCommand.Name
        GetDiskFixed = $null
        GetFeatureUpdate = $null
        ImageFileFullName = $null
        ImageFileItem = $null
        ImageFileName = $null
        ImageFileSource = $null
        ImageFileDestination = $null
        ImageFileUrl = $ImageFileUrl
        IsOnBattery = Get-OSDGather -Property IsOnBattery
        Manufacturer = $Manufacturer
        MSCatalogFirmware = $true
        MSCatalogDiskDrivers = $true
        MSCatalogNetDrivers = $true
        MSCatalogScsiDrivers = $true
        OOBEDeployJsonChildItem = $null
        OOBEDeployJsonItem = $null
        OOBEDeployJsonName = $null
        OOBEDeployJsonObject = $null
        OSBuild = $OSBuild
        OSBuildMenu = $null
        OSBuildNames = $null
        OSEdition = $OSEdition
        OSEditionId = $null
        OSEditionMenu = $null
        OSEditionNames = $null
        OSImageIndex = $ImageIndex
        OSLanguage = $OSLanguage
        OSLanguageMenu = $null
        OSLanguageNames = $null
        OSLicense = $OSLicense
        OSVersion = $OSVersion
        OSVersionMenu = $null
        OSVersionNames = @('Windows 11','Windows 10')
        Product = $Product
        Restart = $Restart
        ScreenshotCapture = $false
        ScreenshotPath = "$env:TEMP\Screenshots"
        Shutdown = $Shutdown
        SkipAutopilot = $SkipAutopilot
        SkipAutopilotOOBE = $null
        SkipODT = $SkipODT
        SkipOOBEDeploy = $null
        TimeStart = Get-Date
        ZTI = $ZTI
    }
    #=================================================
    #	Update Defaults
    #=================================================
    if ($Firmware) {
        $Global:StartOSDCloud.MSCatalogFirmware = $true
    }
    #=================================================
    #	$Global:StartOSDCloudGUI
    #=================================================
    if ($Global:StartOSDCloudGUI) {
        foreach ($Key in $Global:StartOSDCloudGUI.Keys) {
            $Global:StartOSDCloud.$Key = $Global:StartOSDCloudGUI.$Key
        }
    }
    #=================================================
    #	Block
    #=================================================
    Block-StandardUser
    Block-PowerShellVersionLt5
    Block-NoCurl
    #=================================================
    #	-Screenshot
    #=================================================
    if ($PSBoundParameters.ContainsKey('Screenshot')) {
        $Global:StartOSDCloud.ScreenshotCapture = $true
        Start-ScreenPNGProcess -Directory $Global:StartOSDCloud.ScreenshotPath
    }
    #=================================================
    #	Computer Information
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $($Global:StartOSDCloud.Function) | Manufacturer: $Manufacturer | Product: $Product"
    #=================================================
    #	Battery
    #=================================================
    if ($Global:StartOSDCloud.IsOnBattery) {
        Write-Warning "Computer is currently running on Battery"
    }
    #=================================================
    #	-ZTI
    #=================================================
    if ($Global:StartOSDCloud.ZTI) {
        $Global:StartOSDCloud.GetDiskFixed = Get-Disk.fixed | Where-Object {$_.IsBoot -eq $false} | Sort-Object Number

        if (($Global:StartOSDCloud.GetDiskFixed | Measure-Object).Count -lt 2) {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Warning "This Warning is displayed when using the -ZTI parameter"
            Write-Warning "OSDisk will be cleaned automatically without confirmation"
            Write-Warning "Press CTRL + C to cancel"
            $Global:StartOSDCloud.GetDiskFixed | Select-Object -Property Number, BusType, MediaType,`
            FriendlyName, PartitionStyle, NumberOfPartitions,`
            @{Name='SizeGB';Expression={[int]($_.Size / 1000000000)}} | Format-Table
    
            Write-Warning "OSDCloud will continue in 5 seconds"
            Start-Sleep -Seconds 5
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Warning "More than 1 Fixed Disk is present"
            Write-Warning "Disks will not be cleaned automatically"
            $Global:StartOSDCloud.GetDiskFixed | Select-Object -Property Number, BusType, MediaType,`
            FriendlyName, PartitionStyle, NumberOfPartitions,`
            @{Name='SizeGB';Expression={[int]($_.Size / 1000000000)}} | Format-Table
            Start-Sleep -Seconds 5
        }
    }
    #=================================================
    #	Test Web Connection
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test-WebConnection" -NoNewline
    #Write-Host -ForegroundColor DarkGray "google.com"

    if (Test-WebConnection -Uri "google.com") {
        Write-Host -ForegroundColor Green " OK"
    }
    else {
        Write-Host -ForegroundColor Red " FAILED"
        Write-Warning "Could not validate an Internet connection"
        Write-Warning "OSDCloud will continue, but there may be issues if this can't be resolved"
    }
    #=================================================
    #	Custom Image
    #=================================================
    if ($Global:StartOSDCloud.ImageFileFullName -and $Global:StartOSDCloud.ImageFileItem -and $Global:StartOSDCloud.ImageFileName) {
        #Custom Image set in OSDCloudGUI
    }
    #=================================================
    #	ParameterSet CustomImage
    #=================================================
    elseif ($PSCmdlet.ParameterSetName -eq 'CustomImage') {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "Custom Windows Image"

        if ($Global:StartOSDCloud.ImageFileUrl) {
            Write-Host -ForegroundColor DarkGray "ImageFileUrl: $($Global:StartOSDCloud.ImageFileUrl)"
            Write-Host -ForegroundColor DarkGray "ImageIndex: $($Global:StartOSDCloud.OSImageIndex)"
        }
        if ($PSBoundParameters.ContainsKey('FindImageFile')) {
            $Global:StartOSDCloud.ImageFileItem = Select-OSDCloudFileWim
        
            if ($Global:StartOSDCloud.ImageFileItem) {
                $Global:StartOSDCloud.OSImageIndex = Select-OSDCloudImageIndex -ImagePath $Global:StartOSDCloud.ImageFileItem.FullName

                Write-Host -ForegroundColor DarkGray "ImageFileItem: $($Global:StartOSDCloud.ImageFileItem.FullName)"
                Write-Host -ForegroundColor DarkGray "OSImageIndex: $($Global:StartOSDCloud.OSImageIndex)"
            }
            else {
                $Global:StartOSDCloud.ImageFileItem = $null
                $Global:StartOSDCloud.OSImageIndex = 'AUTO'
                #$Global:OSDImageParent = $null
                #$Global:OSDCloudWimFullName = $null
                Write-Warning "Custom Windows Image on USB was not found"
                Break
            }
        }
    }
    #=================================================
    #	ParameterSet Default
    #=================================================
    elseif ($PSCmdlet.ParameterSetName -eq 'Default') {
        #=================================================
        #	OSVersion
        #=================================================
        if ($Global:StartOSDCloud.OSVersion) {
        }
        elseif ($Global:StartOSDCloud.ZTI) {
            $Global:StartOSDCloud.OSVersion = 'Windows 10'
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Select an Operating System"
            $Global:StartOSDCloud.OSVersionNames = @('Windows 11','Windows 10')
            
            $i = $null
            $Global:StartOSDCloud.OSVersionMenu = foreach ($Item in $Global:StartOSDCloud.OSVersionNames) {
                $i++
            
                $ObjectProperties = @{
                    Selection   = $i
                    Name     = $Item
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
            
            $Global:StartOSDCloud.OSVersionMenu | Select-Object -Property Selection, Name | Format-Table | Out-Host
            
            do {
                $SelectReadHost = Read-Host -Prompt "Enter the Selection Number"
            }
            until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $Global:StartOSDCloud.OSVersionMenu.Selection))))
            
            $Global:StartOSDCloud.OSVersion = $Global:StartOSDCloud.OSVersionMenu | Where-Object {$_.Selection -eq $SelectReadHost} | Select-Object -ExpandProperty Name
        }
        $OSVersion = $Global:StartOSDCloud.OSVersion
        #=================================================
        #	Defaults
        #=================================================
        if ($Global:StartOSDCloud.OSVersion -eq 'Windows 11') {
            $Global:StartOSDCloud.OSBuild = '21H2'
        }
        #=================================================
        #	OSBuild
        #=================================================
        if ($Global:StartOSDCloud.OSBuild) {
        }
        elseif ($Global:StartOSDCloud.ZTI) {
            $Global:StartOSDCloud.OSBuild = '21H2'
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Select a Build for $OSVersion x64"
            $Global:StartOSDCloud.OSBuildNames = @('21H2','21H1','20H2','2004','1909','1903','1809')
            
            $i = $null
            $Global:StartOSDCloud.OSBuildMenu = foreach ($Item in $Global:StartOSDCloud.OSBuildNames) {
                $i++
            
                $ObjectProperties = @{
                    Selection   = $i
                    Name     = $Item
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
            
            $Global:StartOSDCloud.OSBuildMenu | Select-Object -Property Selection, Name | Format-Table | Out-Host
            
            do {
                $SelectReadHost = Read-Host -Prompt "Enter the Selection Number"
            }
            until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $Global:StartOSDCloud.OSBuildMenu.Selection))))
            
            $Global:StartOSDCloud.OSBuild = $Global:StartOSDCloud.OSBuildMenu | Where-Object {$_.Selection -eq $SelectReadHost} | Select-Object -ExpandProperty Name
        }
        $OSBuild = $Global:StartOSDCloud.OSBuild
        #=================================================
        #	OSEdition
        #=================================================
        if ($Global:StartOSDCloud.OSEdition) {
        }
        elseif ($ZTI) {
            $Global:StartOSDCloud.OSEdition = 'Enterprise'
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Select an Edition for $OSVersion x64 $OSBuild"
            $Global:StartOSDCloud.OSEditionNames = @('Home','Home N','Home Single Language','Education','Education N','Enterprise','Enterprise N','Pro','Pro N')

            $i = $null
            $Global:StartOSDCloud.OSEditionMenu = foreach ($Item in $Global:StartOSDCloud.OSEditionNames) {
                $i++
            
                $ObjectProperties = @{
                    Selection   = $i
                    Name     = $Item
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
            
            $Global:StartOSDCloud.OSEditionMenu | Select-Object -Property Selection, Name | Format-Table | Out-Host
            
            do {
                $SelectReadHost = Read-Host -Prompt "Enter the Selection Number"
            }
            until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $Global:StartOSDCloud.OSEditionMenu.Selection))))
            
            $Global:StartOSDCloud.OSEdition = $Global:StartOSDCloud.OSEditionMenu | Where-Object {$_.Selection -eq $SelectReadHost} | Select-Object -ExpandProperty Name
        }
        #=================================================
        #	OSEditionId and OSLicense
        #=================================================
        if ($Global:StartOSDCloud.OSEdition -eq 'Home') {
            $Global:StartOSDCloud.OSEditionId = 'Core'
            $Global:StartOSDCloud.OSLicense = 'Retail'
            $Global:StartOSDCloud.OSImageIndex = 4
        }
        if ($Global:StartOSDCloud.OSEdition -eq 'Home N') {
            $Global:StartOSDCloud.OSEditionId = 'CoreN'
            $Global:StartOSDCloud.OSLicense = 'Retail'
            $Global:StartOSDCloud.OSImageIndex = 5
        }
        if ($Global:StartOSDCloud.OSEdition -eq 'Home Single Language') {
            $Global:StartOSDCloud.OSEditionId = 'CoreSingleLanguage'
            $Global:StartOSDCloud.OSLicense = 'Retail'
            $Global:StartOSDCloud.OSImageIndex = 6
        }
        if ($Global:StartOSDCloud.OSEdition -eq 'Enterprise') {
            $Global:StartOSDCloud.OSEditionId = 'Enterprise'
            $Global:StartOSDCloud.OSLicense = 'Volume'
            $Global:StartOSDCloud.OSImageIndex = 6
        }
        if ($Global:StartOSDCloud.OSEdition -eq 'Enterprise N') {
            $Global:StartOSDCloud.OSEditionId = 'EnterpriseN'
            $Global:StartOSDCloud.OSLicense = 'Volume'
            $Global:StartOSDCloud.OSImageIndex = 7
        }
        $OSEdition = $Global:StartOSDCloud.OSEdition
        #=================================================
        #	OSLicense
        #=================================================
        if ($Global:StartOSDCloud.OSLicense) {
        }
        elseif ($Global:StartOSDCloud.ZTI) {
            $Global:StartOSDCloud.OSLicense = 'Volume'
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Select a License for $OSVersion x64 $OSBuild $OSEdition"
            $Global:StartOSDCloud.OSLicenseNames = @('Retail Windows Consumer Editions','Volume Windows Business Editions')
            
            $i = $null
            $Global:StartOSDCloud.OSLicenseMenu = foreach ($Item in $Global:StartOSDCloud.OSLicenseNames) {
                $i++
            
                $ObjectProperties = @{
                    Selection           = $i
                    Name                = $Item
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
            
            $Global:StartOSDCloud.OSLicenseMenu | Select-Object -Property Selection, Name | Format-Table | Out-Host
            
            do {
                $SelectReadHost = Read-Host -Prompt "Enter the Selection Number"
            }
            until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $Global:StartOSDCloud.OSLicenseMenu.Selection))))
            
            $Global:StartOSDCloud.OSLicenseMenu = $Global:StartOSDCloud.OSLicenseMenu | Where-Object {$_.Selection -eq $SelectReadHost} | Select-Object -ExpandProperty Name

            if ($Global:StartOSDCloud.OSLicenseMenu -match 'Retail') {
                $Global:StartOSDCloud.OSLicense = 'Retail'
            }
            else {
                $Global:StartOSDCloud.OSLicense = 'Volume'
            }
            #Write-Host -ForegroundColor Cyan "OSLicense: " -NoNewline
            #Write-Host -ForegroundColor Green $Global:StartOSDCloud.OSLicense
        }
        if ($Global:StartOSDCloud.OSEdition -eq 'Education') {
            $Global:StartOSDCloud.OSEditionId = 'Education'
            if ($Global:StartOSDCloud.OSLicense -eq 'Retail') {$Global:StartOSDCloud.OSImageIndex = 7}
            if ($Global:StartOSDCloud.OSLicense -eq 'Volume') {$Global:StartOSDCloud.OSImageIndex = 4}
        }
        if ($Global:StartOSDCloud.OSEdition -eq 'Education N') {
            $Global:StartOSDCloud.OSEditionId = 'EducationN'
            if ($Global:StartOSDCloud.OSLicense -eq 'Retail') {$Global:StartOSDCloud.OSImageIndex = 8}
            if ($Global:StartOSDCloud.OSLicense -eq 'Volume') {$Global:StartOSDCloud.OSImageIndex = 5}
        }
        if ($Global:StartOSDCloud.OSEdition -eq 'Pro') {
            $Global:StartOSDCloud.OSEditionId = 'Professional'
            if ($Global:StartOSDCloud.OSLicense -eq 'Retail') {$Global:StartOSDCloud.OSImageIndex = 9}
            if ($Global:StartOSDCloud.OSLicense -eq 'Volume') {$Global:StartOSDCloud.OSImageIndex = 8}
        }
        if ($Global:StartOSDCloud.OSEdition -eq 'Pro N') {
            $Global:StartOSDCloud.OSEditionId = 'ProfessionalN'
            if ($Global:StartOSDCloud.OSLicense -eq 'Retail') {$Global:StartOSDCloud.OSImageIndex = 10}
            if ($Global:StartOSDCloud.OSLicense -eq 'Volume') {$Global:StartOSDCloud.OSImageIndex = 9}
        }
        $OSLicense = $Global:StartOSDCloud.OSLicense
        Write-Host -ForegroundColor Cyan "OSEditionId: " -NoNewline
        Write-Host -ForegroundColor Green $Global:StartOSDCloud.OSEditionId
        Write-Host -ForegroundColor Cyan "OSImageIndex: " -NoNewline
        Write-Host -ForegroundColor Green $Global:StartOSDCloud.OSImageIndex
        #=================================================
        #	OSLanguage
        #=================================================
        if ($Global:StartOSDCloud.OSLanguage) {
        }
        elseif ($PSBoundParameters.ContainsKey('OSLanguage')) {
        }
        elseif ($ZTI) {
            $Global:StartOSDCloud.OSLanguage = 'en-us'
        }
        else {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Select a Language for $OSVersion x64 $OSBuild $OSEdition $OSLicense"
            $Global:StartOSDCloud.OSLanguageNames = @('ar-sa','bg-bg','cs-cz','da-dk','de-de','el-gr','en-gb','en-us','es-es','es-mx','et-ee','fi-fi','fr-ca','fr-fr','he-il','hr-hr','hu-hu','it-it','ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl','pl-pl','pt-br','pt-pt','ro-ro','ru-ru','sk-sk','sl-si','sr-latn-rs','sv-se','th-th','tr-tr','uk-ua','zh-cn','zh-tw')
            
            $i = $null
            $Global:StartOSDCloud.OSLanguageMenu = foreach ($Item in $Global:StartOSDCloud.OSLanguageNames) {
                $i++
            
                $ObjectProperties = @{
                    Selection   = $i
                    Name     = $Item
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
            
            $Global:StartOSDCloud.OSLanguageMenu | Select-Object -Property Selection, Name | Format-Table | Out-Host
            
            do {
                $SelectReadHost = Read-Host -Prompt "Enter the Selection number"
            }
            until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $Global:StartOSDCloud.OSLanguageMenu.Selection))))
            
            $Global:StartOSDCloud.OSLanguage = $Global:StartOSDCloud.OSLanguageMenu | Where-Object {$_.Selection -eq $SelectReadHost} | Select-Object -ExpandProperty Name
        }
        $OSLanguage = $Global:StartOSDCloud.OSLanguage
        #=================================================
        #	Get-FeatureUpdate
        #   This is where we take the OSB OSE OSL information and get the
        #   Feature Update.  Global Variables will be set for Deploy-OSDCloud
        #=================================================
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "Get-FeatureUpdate " -NoNewline
        Write-Host -ForegroundColor DarkGray "-OSVersion '$OSVersion' -OSBuild $OSBuild -OSLicense $OSLicense -OSLanguage $OSLanguage"

        $Params = @{
            OSVersion   = $OSVersion
            OSBuild     = $OSBuild
            OSLicense   = $OSLicense
            OSLanguage  = $OSLanguage
        }
        $Global:StartOSDCloud.GetFeatureUpdate = Get-FeatureUpdate @Params

        if ($Global:StartOSDCloud.GetFeatureUpdate) {
            $Global:StartOSDCloud.GetFeatureUpdate = $Global:StartOSDCloud.GetFeatureUpdate | Select-Object -Property CreationDate,KBNumber,Title,UpdateOS,UpdateBuild,UpdateArch,FileName, @{Name='SizeMB';Expression={[int]($_.Size /1024/1024)}},FileUri,Hash,AdditionalHash
            $Global:StartOSDCloud.ImageFileName = $Global:StartOSDCloud.GetFeatureUpdate.FileName
            $Global:StartOSDCloud.ImageFileUrl = $Global:StartOSDCloud.GetFeatureUpdate.FileUri
        }
        else {
            Write-Warning "Unable to locate a Windows Feature Update"
            Write-Warning "OSDCloud cannot continue"
            Break
        }
        #=================================================
        #	Get-FeatureUpdate Offline
        #   Determine if the OS is Offline
        #   Need to bail if the file is Online is not valid or not Offline
        #=================================================
        $Global:StartOSDCloud.ImageFileItem = Find-OSDCloudFile -Name $Global:StartOSDCloud.GetFeatureUpdate.FileName -Path '\OSDCloud\OS\' | Sort-Object FullName | Where-Object {$_.Length -gt 3GB}
        $Global:StartOSDCloud.ImageFileItem = $Global:StartOSDCloud.ImageFileItem | Where-Object {$_.FullName -notlike "C*"} | Where-Object {$_.FullName -notlike "X*"} | Select-Object -First 1

        if ($Global:StartOSDCloud.ImageFileItem) {
            #Write-Host -ForegroundColor Green "OK"
            Write-Host -ForegroundColor DarkGray $Global:StartOSDCloud.GetFeatureUpdate.Title
            Write-Host -ForegroundColor DarkGray $Global:StartOSDCloud.ImageFileItem.FullName
        }
        elseif (Test-WebConnection -Uri $Global:StartOSDCloud.GetFeatureUpdate.FileUri) {
            #Write-Host -ForegroundColor Yellow "Download"
            Write-Host -ForegroundColor Yellow $Global:StartOSDCloud.GetFeatureUpdate.Title
            Write-Host -ForegroundColor Yellow $Global:StartOSDCloud.GetFeatureUpdate.FileUri
        }
        else {
            Write-Warning $Global:StartOSDCloud.GetFeatureUpdate.Title
            Write-Warning $Global:StartOSDCloud.GetFeatureUpdate.FileUri
            Write-Warning "Could not verify an Internet connection for Windows Feature Update"
            Write-Warning "OSDCloud cannot continue"
            Break
        }
    }
    #=================================================
    #   Invoke-OSDCloud.ps1
    #=================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Green "Invoke-OSDCloud ... Starting in 5 seconds..."
    Start-Sleep -Seconds 5
    #Invoke-OSDCloud
    #=================================================








    #=================================================
    #   OSDCloud.ps1 Function goes below

    #function Invoke-OSDCloud {
    $Global:OSDCloud = $null
    $Global:OSDCloud = [ordered]@{
        AutopilotJsonChildItem = $null
        AutopilotJsonItem = $null
        AutopilotJsonName = $null
        AutopilotJsonObject = $null
        AutopilotJsonString = $null
        AutopilotJsonUrl = $null
        AutopilotOOBEJsonChildItem = $null
        AutopilotOOBEJsonItem = $null
        AutopilotOOBEJsonName = $null
        AutopilotOOBEJsonObject = $null
        AzContext = $Global:AzContext
        AzOSDCloudBlobImage = $Global:AzOSDCloudBlobImage
        AzOSDCloudBlobDriverPack = $Global:AzOSDCloudBlobDriverPack
        AzOSDCloudBlobPackage = $Global:AzOSDCloudBlobPackage
        AzOSDCloudDriverPack = $null
        AzOSDCloudImage = $Global:AzOSDCloudImage
        AzOSDCloudPackage = $null
        AzStorageAccounts = $Global:AzStorageAccounts
        AzStorageContext = $Global:AzStorageContext
        BuildName = 'OSDCloud'
        ClearDiskConfirm = [bool]$true
        Debug = $false
        DownloadDirectory = $null
        DownloadName = $null
        DownloadFullName = $null
        DriverPack = $null
        DriverPackBaseName = $null
        DriverPackExpand = [bool]$false
        DriverPackName = $null
        DriverPackOffline = $null
        DriverPackSource = $null
        DriverPackUrl = $null
        Function = $MyInvocation.MyCommand.Name
        GetDiskFixed = $null
        GetFeatureUpdate = $null
        GetMyDriverPack = $null
        HPIADrivers = $null
        HPIAFirmware = $null
        HPIASoftware = $null
        HPTPMUpdate = $null
        HPBIOSUpdate = $null
        ImageCount = $null
        ImageFileFullName = $null
        ImageFileItem = $null
        ImageFileName = $null
        ImageFileSource = $null
        ImageFileDestination = $null
        ImageFileUrl = $null
        IsOnBattery = $(Get-OSDGather -Property IsOnBattery)
        IsVirtualMachine = $(Test-IsVM)
        IsoMountDiskImage = $null
        IsoGetDiskImage = $null
        IsoGetVolume = $null
        Manufacturer = Get-MyComputerManufacturer -Brief
        MSCatalogFirmware = $true
        MSCatalogDiskDrivers = $true
        MSCatalogNetDrivers = $true
        MSCatalogScsiDrivers = $true
        OOBEDeployJsonChildItem = $null
        OOBEDeployJsonItem = $null
        OOBEDeployJsonName = $null
        OOBEDeployJsonObject = $null
        ODTConfigFile = 'C:\OSDCloud\ODT\Config.xml'
        ODTFile = $null
        ODTFiles = $null
        ODTSetupFile = $null
        ODTSource = $null
        ODTTarget = 'C:\OSDCloud\ODT'
        ODTTargetData = 'C:\OSDCloud\ODT\Office'
        OSBuild = $null
        OSBuildMenu = $null
        OSBuildNames = $null
        OSEdition = $null
        OSEditionId = $null
        OSEditionMenu = $null
        OSEditionNames = $null
        OSImageIndex = 1
        OSLanguage = $null
        OSLanguageMenu = $null
        OSLanguageNames = $null
        OSLicense = $null
        OSVersion = 'Windows 10'
        Product = Get-MyComputerProduct
        Restart = [bool]$false
        ScreenshotCapture = $false
        ScreenshotPath = "$env:TEMP\Screenshots"
        SectionPassed = $true
        Shutdown = [bool]$false
        SkipAllDiskSteps = [bool]$false
        SkipAutopilot = [bool]$false
        SkipAutopilotOOBE = [bool]$false
        SkipClearDisk = [bool]$false
        SkipODT = [bool]$false
        SkipOOBEDeploy = [bool]$false
        SkipNewOSDisk = [bool]$false
        SkipRecoveryPartition = [bool]$false
        RecoveryPartition = $null
        Test = [bool]$false
        TimeEnd = $null
        TimeSpan = $null
        TimeStart = Get-Date
        Transcript = $null
        USBPartitions = $null
        Version = [Version](Get-Module -Name OSD -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
        ZTI = [bool]$false
    }
    #endregion
    #=================================================
    #region Set Pre-Merge Defaults
    if ($Global:OSDCloud.IsVirtualMachine) {
        $Global:OSDCloud.SkipRecoveryPartition = $true
    }
    #endregion
    #=================================================
    #region Merge Parameters
    if ($Global:StartOSDCloud) {
        foreach ($Key in $Global:StartOSDCloud.Keys) {
            $Global:OSDCloud.$Key = $Global:StartOSDCloud.$Key
        }
    }
    if ($Global:MyOSDCloud) {
        foreach ($Key in $Global:MyOSDCloud.Keys) {
            $Global:OSDCloud.$Key = $Global:MyOSDCloud.$Key
        }
    }
    #endregion
    #=================================================
    #region Set Post-Merge Defaults
    $Global:OSDCloud.Version = [Version](Get-Module -Name OSD -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version

    if ($Global:OSDCloud.RecoveryPartition -eq $true) {
        $Global:OSDCloud.SkipRecoveryPartition = [bool]$false
    }

    if ($Global:OSDCloud.SkipAllDiskSteps -eq $true) {
        Write-Host -ForegroundColor DarkGray '$OSDCloud.SkipAllDiskSteps = $true'
        $Global:OSDCloud.SkipClearDisk = $true
        $Global:OSDCloud.SkipNewOSDisk = $true
    }

    if ($Global:OSDCloud.Test -eq $true) {
        Write-Host -ForegroundColor DarkGray '$OSDCloud.Test = $true'
        $Global:OSDCloud.SkipClearDisk = $true
        $Global:OSDCloud.SkipNewOSDisk = $true
    }

    if ($Global:OSDCloud.ZTI -eq $true) {
        Write-Host -ForegroundColor DarkGray '$OSDCloud.ZTI = $true'
        $Global:OSDCloud.ClearDiskConfirm = $false
    }
    #endregion
    #=================================================
    #region Helper Functions
    function Write-DarkGrayDate {
        [CmdletBinding()]
        param ()
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
    }
    function Write-DarkGrayLine {
        [CmdletBinding()]
        param ()
        Write-Host -ForegroundColor DarkGray "========================================================================="
    }
    function Write-SectionHeader {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true, Position=0)]
            [System.String]
            $Message
        )
        Write-DarkGrayLine
        Write-DarkGrayDate
        Write-Host -ForegroundColor Cyan $Message
    }
    function Write-SectionSuccess {
        [CmdletBinding()]
        param (
            [Parameter(Position=0)]
            [System.String]
            $Message = 'Success!'
        )
        Write-DarkGrayDate
        Write-Host -ForegroundColor Green $Message
    }
    #endregion
    #=================================================
    #region OSDCloudLogs
    if ($env:SystemDrive -eq 'X:') {
        $OSDCloudLogs = "$env:SystemDrive\OSDCloud\Logs"
        if (-not (Test-Path $OSDCloudLogs)) {
            New-Item $OSDCloudLogs -ItemType Directory -Force | Out-Null
        }
    }
    #endregion
    #=================================================
    #region Fixed Disks
    Write-SectionHeader "Validate Fixed Disks"
    $Global:OSDCloud.SectionPassed = $false

    $Global:OSDCloud.GetDiskFixed = Get-Disk.fixed | Where-Object {$_.IsBoot -eq $false} | Sort-Object Number

    if ($Global:OSDCloud.GetDiskFixed) {
        $Global:OSDCloud.SectionPassed = $true
    }
    else {
        $Global:OSDCloud.SectionPassed = $false
    }

    if ($Global:OSDCloud.SectionPassed -eq $false) {
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "Unable to locate a Fixed Disk. You may need to add additional HDC Drivers to WinPE"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }
    else {
        #Write-SectionSuccess
    }
    #endregion
    #=================================================
    #region Validate Operating System Source
    Write-SectionHeader "Validate Operating System Source"

    $Global:OSDCloud.SectionPassed = $false
    if ($Global:OSDCloud.AzOSDCloudImage) {
        $Global:OSDCloud.SectionPassed = $true
    }
    if ($Global:OSDCloud.ImageFileItem) {
        $Global:OSDCloud.SectionPassed = $true
    }
    if ($Global:OSDCloud.ImageFileDestination) {
        $Global:OSDCloud.SectionPassed = $true
    }
    if ($Global:OSDCloud.ImageFileUrl) {
        $Global:OSDCloud.SectionPassed = $true
    }
    if ($Global:OSDCloud.SectionPassed -eq $false) {
        Write-Warning "OSDCloud Failed"
        Write-Warning "An Operating System Source was not specified by any required Variables"
        Write-Warning "Invoke-OSDCloud should not be run directly unless you know what you are doing"
        Write-Warning "Try using Start-OSDCloud, Start-OSDCloudGUI, or Start-OSDCloudAzure"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }
    else {
        #Write-SectionSuccess
    }
    #endregion
    #=================================================
    #region Autopilot Profiles
    if ($Global:OSDCloud.SkipAutopilot -ne $true) {
        Write-SectionHeader "Validate Autopilot Configuration"

        if ($Global:OSDCloud.AutopilotJsonObject) {
            Write-Host -ForegroundColor DarkGray 'Importing AutopilotJsonObject'
        }
        elseif ($Global:OSDCloud.AutopilotJsonUrl) {
            Write-Host -ForegroundColor DarkGray "Importing Autopilot Configuration $($Global:OSDCloud.AutopilotJsonUrl)"
            if (Test-WebConnection -Uri $Global:OSDCloud.AutopilotJsonUrl) {
                $Global:OSDCloud.AutopilotJsonObject = (Invoke-WebRequest -Uri $Global:OSDCloud.AutopilotJsonUrl).Content | ConvertFrom-Json
            }
        }
        elseif ($Global:OSDCloud.AutopilotJsonItem) {
            $Global:OSDCloud.AutopilotJsonChildItem = Find-OSDCloudFile -Name $Global:OSDCloud.AutopilotJsonItem.Name -Path '\OSDCloud\Autopilot\Profiles\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonChildItem += Find-OSDCloudFile -Name $Global:OSDCloud.AutopilotJsonItem.Name -Path '\OSDCloud\Config\AutopilotJSON\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonItem = $Global:OSDCloud.AutopilotJsonChildItem | Where-Object {$_.FullName -notlike "C*"} | Select-Object -First 1
            if ($Global:OSDCloud.AutopilotJsonItem) {
                $Global:OSDCloud.AutopilotJsonObject = Get-Content $Global:OSDCloud.AutopilotJsonItem.FullName | ConvertFrom-Json
            }
        }
        elseif ($Global:OSDCloud.AutopilotJsonName) {
            $Global:OSDCloud.AutopilotJsonChildItem = Find-OSDCloudFile -Name $Global:OSDCloud.AutopilotJsonName -Path '\OSDCloud\Autopilot\Profiles\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonChildItem += Find-OSDCloudFile -Name $Global:OSDCloud.AutopilotJsonName -Path '\OSDCloud\Config\AutopilotJSON\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonItem = $Global:OSDCloud.AutopilotJsonChildItem | Where-Object {$_.FullName -notlike "C*"} | Select-Object -First 1
            if ($Global:OSDCloud.AutopilotJsonItem) {
                $Global:OSDCloud.AutopilotJsonObject = Get-Content $Global:OSDCloud.AutopilotJsonItem.FullName | ConvertFrom-Json
            }
        }
        else {
            $Global:OSDCloud.AutopilotJsonChildItem = Find-OSDCloudFile -Name "*.json" -Path '\OSDCloud\Autopilot\Profiles\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonChildItem += Find-OSDCloudFile -Name "*.json" -Path '\OSDCloud\Config\AutopilotJSON\' | Sort-Object FullName
            $Global:OSDCloud.AutopilotJsonChildItem = $Global:OSDCloud.AutopilotJsonChildItem | Where-Object {$_.FullName -notlike "C*"}

            if ($Global:OSDCloud.AutopilotJsonChildItem) {
                if ($Global:OSDCloud.ZTI -eq $true) {
                    $Global:OSDCloud.AutopilotJsonItem = $Global:OSDCloud.AutopilotJsonChildItem | Select-Object -First 1
                }
                else {
                    $Global:OSDCloud.AutopilotJsonItem = Select-OSDCloudAutopilotJsonItem
                }

                if ($Global:OSDCloud.AutopilotJsonItem) {
                    $Global:OSDCloud.AutopilotJsonObject = Get-Content $Global:OSDCloud.AutopilotJsonItem.FullName | ConvertFrom-Json
                }
            }
        }

        if ($Global:OSDCloud.AutopilotJsonObject) {
            Write-Host -ForegroundColor DarkGray "OSDCloud will apply the following Autopilot Configuration as AutopilotConfigurationFile.json"
            $($Global:OSDCloud.AutopilotJsonObject) | Out-Host | Format-List
        }
        else {
            Write-Warning "AutopilotConfigurationFile.json will not be configured for this deployment"
        }
    }
    #endregion
    #=================================================
    #region Office Configuration
    if ($Global:OSDCloud.SkipODT -ne $true) {
        $Global:OSDCloud.ODTFiles = Find-OSDCloudODTFile
        
        if ($Global:OSDCloud.ODTFiles) {
            Write-SectionHeader "Select Office Deployment Tool Configuration"
        
            $Global:OSDCloud.ODTFile = Select-OSDCloudODTFile
            if ($Global:OSDCloud.ODTFile) {
                Write-Host -ForegroundColor DarkGray "Office Config: $($Global:OSDCloud.ODTFile.FullName)"
            } 
            else {
                Write-Warning "OSDCloud Office Config will not be configured for this deployment"
            }
        }
    }
    #endregion
    #=================================================
    #region Require WinPE
    Write-SectionHeader "Validate WinPE"

    if ($env:SystemDrive -eq 'X:') {
        $Global:OSDCloud.Test = $false
    }
    else {
        $Global:OSDCloud.Test = $true
    }

    if ($Global:OSDCloud.Test -eq $true) {
        Write-Warning "OSDCloud can only be run from WinPE"
        Write-Warning "OSDCloud is running in Test mode"
        Start-Sleep -Seconds 5
    }
    #endregion
    #=================================================
    #region Remove USB Partition Access Path
    <#
    https://docs.microsoft.com/en-us/powershell/module/storage/remove-partitionaccesspath
    Partition Access Paths are being removed from USB Drive Letters
    This prevents issues when Drive Letters are reassigned
    #>
    $Global:OSDCloud.USBPartitions = Get-Partition.usb
    if ($Global:OSDCloud.USBPartitions) {
        Write-SectionHeader "Removing USB drive letters"

        if ($Global:OSDCloud.Test -eq $false) {
            foreach ($USBPartition in $Global:OSDCloud.USBPartitions) {

                $RemovePartitionAccessPath = @{
                    AccessPath = "$($USBPartition.DriveLetter):"
                    DiskNumber = $USBPartition.DiskNumber
                    PartitionNumber = $USBPartition.PartitionNumber
                }

                Remove-PartitionAccessPath @RemovePartitionAccessPath -ErrorAction Stop
                Start-Sleep -Seconds 3
            }
        }
    }
    #endregion
    #=================================================
    #region Clear-Disk
    <#
    https://docs.microsoft.com/en-us/powershell/module/storage/clear-disk
    Fixed Disks must be cleared before new partitions can be created
    #>
    Write-SectionHeader "Clear-Disk"

    if ($Global:OSDCloud.SkipClearDisk -eq $true) {
        Write-Host -ForegroundColor DarkGray '$OSDCloud.SkipClearDisk = $true'
    }

    if ($Global:OSDCloud.SkipClearDisk -eq $false) {
        Write-Host -ForegroundColor DarkGray '$OSDCloud.SkipClearDisk = $false'

        if (($Global:OSDCloud.GetDiskFixed | Measure-Object).Count -ge 2) {
            Write-Host -ForegroundColor DarkGray 'More than 1 Fixed Disk is present, Clear-Disk Confirm is required'
            $Global:OSDCloud.ClearDiskConfirm = $true
        }

        if ($Global:OSDCloud.ClearDiskConfirm -eq $true) {
            Write-Host -ForegroundColor DarkGray '$OSDCloud.ClearDiskConfirm = $true'
            Clear-Disk.fixed -Force -NoResults -ErrorAction Stop
        }
        else {
            Write-Host -ForegroundColor DarkGray '$OSDCloud.ClearDiskConfirm = $false'
            Clear-Disk.fixed -Force -NoResults -Confirm:$false -ErrorAction Stop
        }
    }
    #endregion
    #=================================================
    #region New-OSDisk
    <#
    https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/configure-uefigpt-based-hard-drive-partitions
    New Partitions will be created using Microsoft Standard Layout
    #>
    Write-SectionHeader "New-OSDisk"

    if ($Global:OSDCloud.SkipNewOSDisk -eq $true) {
        Write-Host -ForegroundColor DarkGray '$OSDCloud.SkipNewOSDisk = $true'
    }

    if ($Global:OSDCloud.SkipNewOSDisk -eq $false) {
        if ($Global:OSDCloud.SkipRecoveryPartition -eq $true) {
            New-OSDisk -PartitionStyle GPT -NoRecoveryPartition -Force -ErrorAction Stop
            Write-Host "=========================================================================" -ForegroundColor Cyan
            Write-Host "| SYSTEM | MSR |                    WINDOWS                             |" -ForegroundColor Cyan
            Write-Host "=========================================================================" -ForegroundColor Cyan
        }
        else {
            New-OSDisk -PartitionStyle GPT -Force -ErrorAction Stop
            Write-Host "=========================================================================" -ForegroundColor Cyan
            Write-Host "| SYSTEM | MSR |                    WINDOWS                  | RECOVERY |" -ForegroundColor Cyan
            Write-Host "=========================================================================" -ForegroundColor Cyan
            #Wait a few seconds to make sure the Disk is set
            Start-Sleep -Seconds 5
        }

        #Make sure that there is a PSDrive 
        if (-NOT (Get-PSDrive -Name 'C')) {
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "New-OSDisk didn't work. There is no PSDrive FileSystem at C:\"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }
    }
    #endregion
    #=================================================
    #region USB Add Partition Access Path
    <#
    https://docs.microsoft.com/en-us/powershell/module/storage/add-partitionaccesspath
    #>
    if ($Global:OSDCloud.USBPartitions) {
        Write-SectionHeader "Restoring USB Drive Letters"

        if ($Global:OSDCloud.Test -eq $false) {
            foreach ($USBPartition in $Global:OSDCloud.USBPartitions) {

                $AddPartitionAccessPath = @{
                    AssignDriveLetter = $true
                    DiskNumber = $USBPartition.DiskNumber
                    PartitionNumber = $USBPartition.PartitionNumber
                }

                Add-PartitionAccessPath @AddPartitionAccessPath
                Start-Sleep -Seconds 5
            }
        }
    }
    #endregion
    #=================================================

    #=======================================================================
    #	Preprovision Bitlocker
    #=======================================================================
    manage-bde -on C: -UsedSpaceOnly -encryptionMethod aes128



    #region ScreenshotCapture
    if ($Global:OSDCloud.ScreenshotCapture) {
        Write-SectionHeader "Moving Screenshots to C:\OSDCloud\Screenshots"
        Write-Verbose -Message "https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy"
        Stop-ScreenPNGProcess
        Invoke-Exe robocopy "$($Global:OSDCloud.ScreenshotPath)" C:\OSDCloud\Screenshots *.* /s /ndl /nfl /njh /njs
        Start-ScreenPNGProcess -Directory 'C:\OSDCloud\Screenshots'
        $Global:OSDCloud.ScreenshotPath = 'C:\OSDCloud\Screenshots'
    }
    #endregion
    #=================================================
    #region Transcript
    Write-SectionHeader "Saving PowerShell Transcript to C:\OSDCloud\Logs"

    Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.host/start-transcript"

    if (-NOT (Test-Path 'C:\OSDCloud\Logs')) {
        New-Item -Path 'C:\OSDCloud\Logs' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    
    $Global:OSDCloud.Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Deploy-OSDCloud.log"
    Start-Transcript -Path (Join-Path 'C:\OSDCloud\Logs' $Global:OSDCloud.Transcript) -ErrorAction Ignore
    #endregion
    #=================================================
    #region Performance Final
    #https://docs.microsoft.com/en-us/windows/win32/power/power-policy-settings
    Write-SectionHeader "Powercfg High Performance"

    if ($Global:OSDCloud.IsOnBattery -eq $true) {
        Write-Host -ForegroundColor DarkGray "Device is on battery power. Performance will not be adjusted"
    }
    elseif ($Global:OSDCloud.Test -eq $true) {
        Write-Host -ForegroundColor DarkGray "Device is running in test mode. Performance will not be adjusted"
    }
    elseif ($Global:OSDCloud.Debug -eq $true) {
        Write-Host -ForegroundColor DarkGray "Device is running in debug mode. Performance will not be adjusted"
    }
    else {
        Write-Host -ForegroundColor DarkGray "Enable powercfg High Performance"
        Invoke-Exe powercfg.exe -SetActive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    }
    #endregion
    #=================================================
    #region Image File Offline
    if ($Global:OSDCloud.ImageFileItem) {
        Write-SectionHeader "Copy Offline Windows Image (Copy-Item)"
        Write-Verbose -Message "Copying Microsoft Windows Image from Offline Source"

        #It's possible that Drive Letters may have changed if a USB is used

        #Check to see if the image file exists already after the USB Drive has been reinitialized
        if (Test-Path $Global:OSDCloud.ImageFileItem.FullName) {
            $Global:OSDCloud.ImageFileSource = Get-Item -Path $Global:OSDCloud.ImageFileItem.FullName
        }

        #Set the ImageFile Name if it does not exist
        if (!($Global:OSDCloud.ImageFileName)) {
            $Global:OSDCloud.ImageFileName = Split-Path -Path $Global:OSDCloud.ImageFileItem.FullName -Leaf
        }

        #If the Source did not exist after the USB, have to do a best guess
        if (!($Global:OSDCloud.ImageFileSource)) {
            $Global:OSDCloud.ImageFileSource = Find-OSDCloudFile -Name $Global:OSDCloud.ImageFileName -Path (Split-Path -Path (Split-Path -Path $Global:OSDCloud.ImageFileItem.FullName -Parent) -NoQualifier) | Where-Object {$_.FullName -notlike "C:*"} | Select-Object -First 1
        }

        #Now that we have an ImageFileSource, everything is good
        if ($Global:OSDCloud.ImageFileSource) {
            Write-Host -ForegroundColor DarkGray "-Source $($Global:OSDCloud.ImageFileSource.FullName)"
            if (!(Test-Path 'C:\OSDCloud\OS')) {
                New-Item -Path 'C:\OSDCloud\OS' -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            Copy-Item -Path $Global:OSDCloud.ImageFileSource.FullName -Destination 'C:\OSDCloud\OS' -Force
            if (Test-Path "C:\OSDCloud\OS\$($Global:OSDCloud.ImageFileSource.Name)") {
                $Global:OSDCloud.ImageFileDestination = Get-Item -Path "C:\OSDCloud\OS\$($Global:OSDCloud.ImageFileSource.Name)"
            }
        }
        if ($Global:OSDCloud.ImageFileDestination) {
            Write-Host -ForegroundColor DarkGray "-Destination $($Global:OSDCloud.ImageFileDestination.FullName)"
            $Global:OSDCloud.ImageFileUrl = $null
        }
        else {
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Could not copy the Windows Image to C:\OSDCloud\OS"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }
    }
    #endregion
    #=================================================
    #region Get Image File
    if ($Global:OSDCloud.AzOSDCloudImage) {
        #AzOSDCloud
    }
    elseif (!($Global:OSDCloud.ImageFileDestination) -and (!($Global:OSDCloud.ImageFileUrl))) {
        Write-SectionHeader "Get-FeatureUpdate"
        Write-Warning "Invoke-OSDCloud was not set properly with an OS to Download"
        Write-Warning "You should be using Start-OSDCloud or Start-OSDCloudGUI"
        Write-Warning "Invoke-OSDCloud should not be run directly unless you know what you are doing"
        Write-Warning "Windows 10 Enterprise is being downloaded and installed out of convenience only"

        if (!($Global:OSDCloud.GetFeatureUpdate)) {
            $Global:OSDCloud.GetFeatureUpdate = Get-FeatureUpdate
        }
        if ($Global:OSDCloud.GetFeatureUpdate) {
            $Global:OSDCloud.GetFeatureUpdate = $Global:OSDCloud.GetFeatureUpdate | Select-Object -Property CreationDate,KBNumber,Title,UpdateOS,UpdateBuild,UpdateArch,FileName, @{Name='SizeMB';Expression={[int]($_.Size /1024/1024)}},FileUri,Hash,AdditionalHash
            $Global:OSDCloud.ImageFileName = $Global:OSDCloud.GetFeatureUpdate.FileName
            $Global:OSDCloud.ImageFileUrl = $Global:OSDCloud.GetFeatureUpdate.FileUri
            $Global:OSDCloud.OSImageIndex = 6
        }
        else {
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Unable to locate a Windows Feature Update"
            Write-Warning "OSDCloud cannot continue"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }
    }
    #endregion
    #=================================================
    #region Azure Storage Windows Image Download
    if ($Global:OSDCloud.AzOSDCloudImage) {
        Write-SectionHeader "OSDCloud Azure Storage Windows Image Download"

        $Global:OSDCloud.DownloadDirectory = "C:\OSDCloud\Azure\$($Global:OSDCloud.AzOSDCloudImage.BlobClient.AccountName)\$($Global:OSDCloud.AzOSDCloudImage.BlobClient.BlobContainerName)"
        $Global:OSDCloud.DownloadName = $(Split-Path $Global:OSDCloud.AzOSDCloudImage.Name -Leaf)
        $Global:OSDCloud.DownloadFullName = "$($Global:OSDCloud.DownloadDirectory)\$($Global:OSDCloud.DownloadName)"

        #Export Image Information
        $Global:OSDCloud.AzOSDCloudImage | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudImage.json" -Encoding ascii -Width 2000

        $GetAzStorageBlobContent = @{
            CloudBlob = $Global:OSDCloud.AzOSDCloudImage.ICloudBlob
            Context = $Global:OSDCloud.AzOSDCloudImage.Context
            Destination = $Global:OSDCloud.DownloadFullName
            Force = $true
        }

        $NewItem = @{
            Force = $true
            ItemType = 'Directory'
            Path = $Global:OSDCloud.DownloadDirectory
        }

        if (Test-Path $Global:OSDCloud.DownloadFullName) {
            Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $($Global:OSDCloud.DownloadFullName) already exists"

            $Global:OSDCloud.ImageFileDestination = Get-Item -Path $Global:OSDCloud.DownloadFullName -ErrorAction Stop | Select-Object -First 1 | Select-Object -First 1

            if ($Global:OSDCloud.AzOSDCloudImage.Length -eq $Global:OSDCloud.ImageFileDestination.Length) {
                Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Destination file size matches Azure Storage, skipping previous download"
            }
            else {
                Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Existing file does not match Azure Storage, downloading updated file"
                Get-AzStorageBlobContent @GetAzStorageBlobContent -ErrorAction Stop
            }
        }
        else {
            if (-not (Test-Path "$($Global:OSDCloud.DownloadDirectory)")) {
                Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Creating directory $($Global:OSDCloud.DownloadDirectory)"
                $null = New-Item @NewItem -ErrorAction Ignore
            }
            Get-AzStorageBlobContent @GetAzStorageBlobContent -ErrorAction Stop
        }
        
        $Global:OSDCloud.ImageFileDestination = Get-Item -Path $Global:OSDCloud.DownloadFullName -ErrorAction Stop | Select-Object -First 1 | Select-Object -First 1
    }
    #endregion
    #=================================================
    #region Image Download
    if (!($Global:OSDCloud.ImageFileDestination) -and ($Global:OSDCloud.ImageFileUrl)) {
        Write-SectionHeader "Download Operating System"
        Write-Host -ForegroundColor DarkGray "$($Global:OSDCloud.ImageFileUrl)"

        $null = New-Item -Path 'C:\OSDCloud\OS' -ItemType Directory -Force -ErrorAction Ignore

        if (Test-WebConnection -Uri $Global:OSDCloud.ImageFileUrl) {
            if ($Global:OSDCloud.ImageFileName) {
                #=================================================
                #	Cache to USB
                #=================================================
                $OSDCloudUSB = Get-Volume.usb | Where-Object {($_.FileSystemLabel -match 'OSDCloud') -or ($_.FileSystemLabel -match 'BHIMAGE')} | Where-Object {$_.SizeGB -ge 8} | Where-Object {$_.SizeRemainingGB -ge 5} | Select-Object -First 1
                
                if ($OSDCloudUSB -and $Global:OSDCloud.OSVersion -and $Global:OSDCloud.OSBuild) {
                    $OSDownloadChildPath = "$($OSDCloudUSB.DriveLetter):\OSDCloud\OS\$($Global:OSDCloud.OSVersion) $($Global:OSDCloud.OSBuild)"
                    Write-Host -ForegroundColor Yellow "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Downloading to OSDCloudUSB at $OSDownloadChildPath"

                    $OSDCloudUsbOS = Save-WebFile -SourceUrl $Global:OSDCloud.ImageFileUrl -DestinationDirectory "$OSDownloadChildPath" -DestinationName $Global:OSDCloud.ImageFileName

                    if ($OSDCloudUsbOS) {
                        Write-SectionHeader "Copying Operating System to C:\OSDCloud\OS\$($OSDCloudUsbOS.Name)"
                        $null = Copy-Item -Path $OSDCloudUsbOS.FullName -Destination "C:\OSDCloud\OS" -Force

                        $Global:OSDCloud.ImageFileDestination = Get-Item "C:\OSDCloud\OS\$($OSDCloudUsbOS.Name)"
                    }
                }
                else {
                    $Global:OSDCloud.ImageFileDestination = Save-WebFile -SourceUrl $Global:OSDCloud.ImageFileUrl -DestinationDirectory 'C:\OSDCloud\OS' -DestinationName $Global:OSDCloud.ImageFileName -ErrorAction Stop
                }
            }
            else {
                $Global:OSDCloud.ImageFileDestination = Save-WebFile -SourceUrl $Global:OSDCloud.ImageFileUrl -DestinationDirectory 'C:\OSDCloud\OS' -ErrorAction Stop
            }
            if (!(Test-Path $Global:OSDCloud.ImageFileDestination.FullName)) {
                $Global:OSDCloud.ImageFileDestination = Get-ChildItem -Path 'C:\OSDCloud\OS\*' -Include *.wim,*.esd,*.iso | Select-Object -First 1
            }
        }
        else {
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Could not verify an Internet connection for the Windows ImageFile"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }

        if ($Global:OSDCloud.ImageFileDestination) {
            Write-Verbose -Message "ImageFileDestination: $($Global:OSDCloud.ImageFileDestination.FullName)"
        }
    }
    #endregion
    #=================================================
    #region ImageFileDestination
    if (-not ($Global:OSDCloud.ImageFileDestination)) {
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "The Windows Image Source did not download properly to the Destination"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }
    #endregion
    #=================================================
    #region ISO Image File
    if ($Global:OSDCloud.ImageFileDestination.Extension -eq '.iso') {
        Write-SectionHeader "OSDCloud Windows ISO Deployment"

        $Global:OSDCloud.IsoGetDiskImage = Get-DiskImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName

        #ISO is already mounted (which should not be happening)
        if ($Global:OSDCloud.IsoGetDiskImage.Attached) {
            $Global:OSDCloud.IsoGetVolume = $Global:OSDCloud.IsoGetDiskImage | Get-Volume
            Write-Host -ForegroundColor DarkGray "Windows ISO is attached to Drive Letter $($Global:OSDCloud.IsoGetVolume.DriveLetter)"
        }
        else {
            Write-Host -ForegroundColor DarkGray "Mounting Windows ISO $($Global:OSDCloud.ImageFileDestination.FullName)"
            $Global:OSDCloud.IsoMountDiskImage = Mount-DiskImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName -PassThru -ErrorAction Stop

            if ($Global:OSDCloud.IsoMountDiskImage.Attached) {
                Start-Sleep -Seconds 10
                $Global:OSDCloud.IsoGetVolume = $Global:OSDCloud.IsoMountDiskImage | Get-Volume

                Write-Host -ForegroundColor DarkGray "Windows ISO is attached to Drive Letter $($Global:OSDCloud.IsoGetVolume.DriveLetter)"
            }
            else {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
                Write-Warning "The Windows ISO did not mount properly"
                Write-Warning "Press Ctrl+C to exit"
                Start-Sleep -Seconds 86400
                Exit
            }
        }
        $Global:OSDCloud.ImageFileDestination = Get-ChildItem -Path "$($Global:OSDCloud.IsoGetVolume.DriveLetter):\*" -Include *.wim,*.esd -Recurse | Sort-Object Length -Descending | Select-Object -First 1

        if (-not ($Global:OSDCloud.ImageFileDestination)) {
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Unable to find a WIM or ESD file on the Mounted Windows ISO"
            Write-Warning "Press Ctrl+C to exit"
            Start-Sleep -Seconds 86400
            Exit
        }
    }
    #endregion
    #=================================================
    #region ImageIndex
    Write-SectionHeader "Validate Windows Image Index"

    if (-NOT (Test-Path 'C:\OSDCloud\Temp')) {
        New-Item 'C:\OSDCloud\Temp' -ItemType Directory -Force | Out-Null
    }
    #=================================================
    #	Make sure the Windows Image exists
    #=================================================
    if (Test-Path $Global:OSDCloud.ImageFileDestination.FullName) {
        $Global:OSDCloud.ImageCount = (Get-WindowsImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName).Count
        #=================================================
        #	Bad Image
        #=================================================
        if ($null -eq $Global:OSDCloud.ImageCount) {
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Could not read the Windows Image properly"
            Start-Sleep -Seconds 86400
            Stop-Computer -Force
            Exit
        }
        #=================================================
        #TODO: Make sure the ImageIndex is 1
        #=================================================
        elseif ($Global:OSDCloud.ImageCount -eq 1) {
            $Global:OSDCloud.OSImageIndex = 1
        }
        #=================================================
        #	AUTO ImageIndex
        #=================================================
        elseif ($Global:OSDCloud.OSImageIndex -match 'AUTO') {
            $Global:OSDCloud.OSImageIndex = 'AUTO'
        }
        elseif (-not ($Global:OSDCloud.OSImageIndex)) {
            $Global:OSDCloud.OSImageIndex = 'AUTO'
        }
        elseif ($null -eq $Global:OSDCloud.OSImageIndex) {
            $Global:OSDCloud.OSImageIndex = 'AUTO'
        }
        #=================================================
        #	Home Single Language Correction
        #=================================================
        if (($OSLicense -eq 'Retail') -and ($Global:OSDCloud.ImageCount -eq 9)) {
            if ($OSEdition -eq 'Home Single Language') {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
                Write-Warning "This ESD does not contain a Home Single Edition Index"
                Write-Warning "Restart OSDCloud and select a different Edition"
                Start-Sleep -Seconds 86400
                Stop-Computer -Force
                Exit
            }
            if ($OSEdition -notmatch 'Home') {
                Write-Warning "This ESD does not contain a Home Single Edition Index"
                Write-Warning "Adjusting selected ImageIndex by -1"
                $Global:OSDCloud.OSImageIndex = ($Global:OSDCloud.OSImageIndex - 1)
            }
        }
    }
    else {
        #=================================================
        #	FAILED
        #=================================================
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "Could not find a proper Windows Image for deployment"
        Write-Warning "Press Ctrl+C to exit"
        Start-Sleep -Seconds 86400
        Exit
    }

    if ($Global:OSDCloud.OSImageIndex -eq 'AUTO') {
        Write-SectionHeader "Select the Windows Image to expand"
        $SelectedWindowsImage = Get-WindowsImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName | Where-Object {$_.ImageSize -gt 3000000000}

        if ($SelectedWindowsImage) {
            $SelectedWindowsImage | Select-Object -Property ImageIndex, ImageName | Format-Table | Out-Host
    
            do {
                $SelectReadHost = Read-Host -Prompt "Select an Image to apply by ImageIndex [Number]"
            }
            until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $SelectedWindowsImage.ImageIndex))))
    
            #$Global:OSDCloud.OSImageIndex = $SelectedWindowsImage | Where-Object {$_.ImageIndex -eq $SelectReadHost}
            $Global:OSDCloud.OSImageIndex = $SelectReadHost
        }
    }
    #endregion
    #=================================================
    #region Expand-WindowsImage
    Write-SectionHeader "Expand-WindowsImage"
    #Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/dism/expand-windowsimage"

    if (-NOT (Test-Path 'C:\OSDCloud\Temp')) {
        New-Item 'C:\OSDCloud\Temp' -ItemType Directory -Force | Out-Null
    }

    if (Test-Path $Global:OSDCloud.ImageFileDestination.FullName) {
        $Global:OSDCloud.ImageCount = (Get-WindowsImage -ImagePath $Global:OSDCloud.ImageFileDestination.FullName).Count

        if ($null -eq $Global:OSDCloud.ImageCount) {
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
            Write-Warning "Could not read the Windows Image properly"
            Start-Sleep -Seconds 86400
            Stop-Computer -Force
            Exit
        }
        elseif ($Global:OSDCloud.ImageCount -eq 1) {
            $Global:OSDCloud.OSImageIndex = 1
        }
        elseif ((!($Global:OSDCloud.OSImageIndex)) -or ($Global:OSDCloud.OSImageIndex -eq 'Auto')) {
            Write-Warning "No ImageIndex is specified, setting ImageIndex = 1"
            $Global:OSDCloud.OSImageIndex = 1
        }
        #=================================================
        #	FAILED
        #=================================================
        if (($OSLicense -eq 'Retail') -and ($Global:OSDCloud.ImageCount -eq 9)) {
            if ($OSEdition -eq 'Home Single Language') {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
                Write-Warning "This ESD does not contain a Home Single Edition Index"
                Write-Warning "Restart OSDCloud and select a different Edition"
                Start-Sleep -Seconds 86400
                Stop-Computer -Force
                Exit
            }
            if ($OSEdition -notmatch 'Home') {
                Write-Warning "This ESD does not contain a Home Single Edition Index"
                Write-Warning "Adjusting selected ImageIndex by -1"
                $Global:OSDCloud.OSImageIndex = ($Global:OSDCloud.OSImageIndex - 1)
            }
        }

        Write-Host -ForegroundColor DarkGray "-ApplyPath 'C:\'"
        Write-Host -ForegroundColor DarkGray "-ImagePath $($Global:OSDCloud.ImageFileDestination.FullName)"
        Write-Host -ForegroundColor DarkGray "-Index $($Global:OSDCloud.OSImageIndex)"
        Write-Host -ForegroundColor DarkGray "-ScratchDirectory 'C:\OSDCloud\Temp'"
        if ($Global:OSDCloud.Test -eq $false) {
            Expand-WindowsImage -ApplyPath 'C:\' -ImagePath $Global:OSDCloud.ImageFileDestination.FullName -Index $Global:OSDCloud.OSImageIndex -ScratchDirectory 'C:\OSDCloud\Temp' -ErrorAction Stop

            $SystemDrive = Get-Partition | Where-Object {$_.Type -eq 'System'} | Select-Object -First 1
            if (-NOT (Get-PSDrive -Name S)) {
                $SystemDrive | Set-Partition -NewDriveLetter 'S'
            }
            bcdboot C:\Windows /s S: /f ALL
            Start-Sleep -Seconds 10
            $SystemDrive | Remove-PartitionAccessPath -AccessPath "S:\"
        }
    }
    else {
        #=================================================
        #	FAILED
        #=================================================
        Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloud Failed"
        Write-Warning "Could not find a proper Windows Image for deployment"
        Start-Sleep -Seconds 86400
        Stop-Computer -Force
        Exit
    }
    #endregion
    #=================================================
    #region Packages
    Write-SectionHeader 'OSDCloud Azure Container as a Task Sequence'
    if ($Global:OSDCloud.AzOSDCloudPackage) {
        foreach ($Item in $Global:OSDCloud.AzOSDCloudPackage) {

            if (!(Test-Path 'C:\OSDCloud\Packages')) {
                $null = New-Item 'C:\OSDCloud\Packages' -ItemType Directory -Force
            }

            $GetAzStorageBlobContent = @{
                CloudBlob = $Item.ICloudBlob
                Context = $Item.Context
                Destination = 'C:\OSDCloud\Packages\'
                Force = $true
            }

            $null = Get-AzStorageBlobContent @GetAzStorageBlobContent -ErrorAction Ignore
        }

        $Packages = Get-ChildItem -Path 'C:\OSDCloud\Packages\' *.ppkg -Recurse -ErrorAction Ignore

        foreach ($Item in $Packages) {
            Write-DarkGrayDate
            Write-Host -ForegroundColor DarkGray "Add-ProvisioningPackage $($Item.FullName)"
            $Dism = "dism.exe"
            $ArgumentList = "/Image=C:\ /Add-ProvisioningPackage /PackagePath:$($Item.FullName)"
            $null = Start-Process -FilePath 'dism.exe' -ArgumentList $ArgumentList -Wait -NoNewWindow
        }
    }
    #endregion
    #=================================================
    #region Required Directories
    if (-NOT (Test-Path 'C:\Drivers')) {
        New-Item -Path 'C:\Drivers' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    if (-NOT (Test-Path 'C:\Windows\Panther')) {
        New-Item -Path 'C:\Windows\Panther' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    if (-NOT (Test-Path 'C:\Windows\Provisioning\Autopilot')) {
        New-Item -Path 'C:\Windows\Provisioning\Autopilot' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    if (-NOT (Test-Path 'C:\Windows\Setup\Scripts')) {
        New-Item -Path 'C:\Windows\Setup\Scripts' -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    #endregion
    #=================================================
    #region Validate OSDCloud Driver Pack
    Write-SectionHeader "OSDCloud DriverPack"
    if ($Global:OSDCloud.DriverPackName) {
        if ($Global:OSDCloud.DriverPackName -match 'None') {
            Write-Host -ForegroundColor DarkGray "DriverPack is set to None"
            $Global:OSDCloud.DriverPack = $null
        }
        elseif ($Global:OSDCloud.DriverPackName -match 'Microsoft Update Catalog') {
            Write-Host -ForegroundColor DarkGray "DriverPack is set to Microsoft Update Catalog"
            $Global:OSDCloud.DriverPack = $null
        }
        else {
            $Global:OSDCloud.DriverPack = Get-OSDCloudDriverPacks | Where-Object {$_.Name -eq $Global:OSDCloud.DriverPackName} | Select-Object -First 1
        }
    }
    else {
        $Global:OSDCloud.DriverPack = Get-OSDCloudDriverPack | Select-Object -First 1
    }

    if ($Global:OSDCloud.DriverPack) {
        Write-Host -ForegroundColor DarkGray "DriverPack has been matched to $($Global:OSDCloud.DriverPack.Name)"
        $Global:OSDCloud.DriverPackBaseName = ($Global:OSDCloud.DriverPack.FileName).Split('.')[0]
    }

    if ($Global:OSDCloud.AzOSDCloudBlobDriverPack -and $Global:OSDCloud.DriverPackBaseName) {
        Write-Host -ForegroundColor DarkGray "Searching for DriverPack in Azure Storage"
        $Global:OSDCloud.AzOSDCloudDriverPack = $Global:OSDCloud.AzOSDCloudBlobDriverPack | Where-Object {$_.Name -match $Global:OSDCloud.DriverPackBaseName} | Select-Object -First 1

        if ($Global:OSDCloud.AzOSDCloudDriverPack) {
            Write-Host -ForegroundColor DarkGray "DriverPack has been located in Azure Storage"
            $Global:OSDCloud.AzOSDCloudDriverPack | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudDriverPack.json" -Encoding ascii -Width 2000
        }
    }

    if ($Global:OSDCloud.DriverPack) {
        $SaveMyDriverPack = $null
        $Global:OSDCloud.DriverPackBaseName = ($Global:OSDCloud.DriverPack.FileName).Split('.')[0]
        Write-Host -ForegroundColor DarkGray "Matching DriverPack identified"
        Write-Host -ForegroundColor DarkGray "-Name $($Global:OSDCloud.DriverPack.Name)"
        Write-Host -ForegroundColor DarkGray "-BaseName $($Global:OSDCloud.DriverPackBaseName)"
        Write-Host -ForegroundColor DarkGray "-Product $($Global:OSDCloud.DriverPack.Product)"
        Write-Host -ForegroundColor DarkGray "-FileName $($Global:OSDCloud.DriverPack.FileName)"
        Write-Host -ForegroundColor DarkGray "-Url $($Global:OSDCloud.DriverPack.Url)"
        $Global:OSDCloud.DriverPackOffline = Find-OSDCloudFile -Name $Global:OSDCloud.DriverPack.FileName -Path '\OSDCloud\DriverPacks\' | Sort-Object FullName
        $Global:OSDCloud.DriverPackOffline = $Global:OSDCloud.DriverPackOffline | Where-Object {$_.FullName -notlike "C*"} | Where-Object {$_.FullName -notlike "X*"} | Select-Object -First 1
        if ($Global:OSDCloud.DriverPackOffline) {
            Write-Host -ForegroundColor DarkGray "DriverPack is available on OSDCloudUSB and will not be downloaded"
            Write-Host -ForegroundColor DarkGray $Global:OSDCloud.DriverPack.Name
            Write-Host -ForegroundColor DarkGray $Global:OSDCloud.DriverPackOffline.FullName
            #$Global:OSDCloud.DriverPackSource = Find-OSDCloudFile -Name (Split-Path -Path $Global:OSDCloud.DriverPackOffline -Leaf) -Path (Split-Path -Path (Split-Path -Path $Global:OSDCloud.DriverPackOffline.FullName -Parent) -NoQualifier) | Select-Object -First 1
            $Global:OSDCloud.DriverPackSource = $Global:OSDCloud.DriverPackOffline
        }
        if ($Global:OSDCloud.DriverPackSource) {
            Write-Host -ForegroundColor DarkGray "DriverPack is being copied from OSDCloudUSB at $($Global:OSDCloud.DriverPackSource.FullName) to C:\Drivers"
            Copy-Item -Path $Global:OSDCloud.DriverPackSource.FullName -Destination 'C:\Drivers' -Force
            $Global:OSDCloud.DriverPackExpand = $true
        }
        elseif ($Global:OSDCloud.AzOSDCloudDriverPack) {
            Write-Host -ForegroundColor DarkGray "DriverPack is being downloaded from Azure Storage to C:\Drivers"
            $null = New-Item -Path 'C:\OSDCloud\Drivers' -ItemType Directory -Force -ErrorAction Ignore
            Get-AzStorageBlobContent -CloudBlob $Global:OSDCloud.AzOSDCloudDriverPack.ICloudBlob -Context $Global:OSDCloud.AzOSDCloudDriverPack.Context -Destination "C:\Drivers\$(Split-Path $Global:OSDCloud.AzOSDCloudDriverPack.Name -Leaf)"
            $Global:OSDCloud.DriverPackExpand = $true
        }
        elseif ($Global:OSDCloud.DriverPack.Guid) {
            $SaveMyDriverPack = Save-MyDriverPack -DownloadPath 'C:\Drivers' -Expand -Guid $Global:OSDCloud.DriverPack.Guid
        }
        if ($Global:OSDCloud.DriverPackExpand) {
            $DriverPacks = Get-ChildItem -Path 'C:\Drivers' -File

            foreach ($Item in $DriverPacks) {
                $SaveMyDriverPack = $Item.FullName
                $ExpandFile = $Item.FullName
                Write-Verbose -Verbose "DriverPack: $ExpandFile"
                #=================================================
                #   Cab
                #=================================================
                if ($Item.Extension -eq '.cab') {
                    $DestinationPath = Join-Path $Item.Directory $Item.BaseName
        
                    if (-NOT (Test-Path "$DestinationPath")) {
                        New-Item $DestinationPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
                        Write-Host -ForegroundColor DarkGray "DriverPack CAB is being expanded to $DestinationPath"
                        Expand -R "$ExpandFile" -F:* "$DestinationPath" | Out-Null
                    }
                    Continue
                }
                #=================================================
                #   Zip
                #=================================================
                if ($Item.Extension -eq '.zip') {
                    $DestinationPath = Join-Path $Item.Directory $Item.BaseName
    
                    if (-NOT (Test-Path "$DestinationPath")) {
                        Write-Host -ForegroundColor DarkGray "DriverPack ZIP is being expanded to $DestinationPath"
                        Expand-Archive -Path $ExpandFile -DestinationPath $DestinationPath -Force
                    }
                    Continue
                }
                #=================================================
            }
        }

        if ($SaveMyDriverPack) {
            if (-not ($Global:OSDCloud.DriverPackSource)) {
                #=================================================
                #	Cache to OSDCloudUSB
                #=================================================
                $OSDCloudUSB = Get-Volume.usb | Where-Object {($_.FileSystemLabel -match 'OSDCloud') -or ($_.FileSystemLabel -match 'BHIMAGE')} | Where-Object {$_.SizeGB -ge 8} | Where-Object {$_.SizeRemainingGB -ge 2} | Select-Object -First 1
                if ($OSDCloudUSB) {
                    $OSDCloudUSBDestination = "$($OSDCloudUSB.DriveLetter):\OSDCloud\DriverPacks\$($Global:OSDCloud.Manufacturer)"
                    Write-Host -ForegroundColor Yellow "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Copying Driver Pack to OSDCloudUSB at $OSDCloudUSBDestination"
                    If (! (Test-Path $OSDCloudUSBDestination)) {
                        $null = New-Item -Path $OSDCloudUSBDestination -ItemType Directory -Force
                    }
                    $null = Copy-Item -Path $SaveMyDriverPack.FullName -Destination $OSDCloudUSBDestination -Force -PassThru -ErrorAction Stop
                }
            }
        }
    }
    #endregion
    #=================================================
    #region MSCatalogFirmware Final
    Write-SectionHeader "Microsoft Update Catalog Firmware"

    if ($OSDCloud.IsOnBattery -eq $true) {
        Write-Host -ForegroundColor DarkGray "Microsoft Update Catalog Firmware is not enabled for devices on battery power"
    }
    elseif ($OSDCloud.IsVirtualMachine) {
        Write-Host -ForegroundColor DarkGray "Microsoft Update Catalog Firmware is not enabled for Virtual Machines"
    }
    elseif ($Global:OSDCloud.MSCatalogFirmware -eq $false) {
        Write-Host -ForegroundColor DarkGray "Microsoft Update Catalog Firmware is not enabled for this deployment"
    }
    else {
        if (Test-MicrosoftUpdateCatalog) {
            Write-Host -ForegroundColor DarkGray "Firmware Updates will be downloaded from Microsoft Update Catalog to C:\Drivers\Firmware"
            Write-Host -ForegroundColor DarkGray "Some systems do not support a driver Firmware Update"
            Write-Host -ForegroundColor DarkGray "You may have to enable this setting in your BIOS or Firmware Settings"
    
            Save-SystemFirmwareUpdate -DestinationDirectory 'C:\Drivers\Firmware'
        }
        else {
            Write-Warning "Unable to download or find firware for his Device"
        }
    }
    #endregion
    #=================================================
    #region MSCatalogDrivers Final
    Write-SectionHeader "Microsoft Update Catalog Drivers"

    if ($Global:OSDCloud.DriverPackName -eq 'None') {
        Write-Host -ForegroundColor DarkGray "Drivers from Microsoft Update Catalog will not be applied for this deployment"
    }
    else {
        if (Test-MicrosoftUpdateCatalog) {
            if ($Global:OSDCloud.DriverPackName -eq 'Microsoft Update Catalog') {
                Write-Host -ForegroundColor DarkGray "Drivers for all devices will be downloaded from Microsoft Update Catalog to C:\Drivers"
                Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers'
            }
            elseif ($null -eq $SaveMyDriverPack) {
                Write-Host -ForegroundColor DarkGray "Drivers for all devices will be downloaded from Microsoft Update Catalog to C:\Drivers"
                Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers'
            }
            else {
                if ($OSDCloud.MSCatalogDiskDrivers) {
                    Write-Host -ForegroundColor DarkGray "Drivers for PNPClass DiskDrive will be downloaded from Microsoft Update Catalog to C:\Drivers"
                    Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers' -PNPClass 'DiskDrive'
                }
                if ($OSDCloud.MSCatalogNetDrivers) {
                    Write-Host -ForegroundColor DarkGray "Drivers for PNPClass Net will be downloaded from Microsoft Update Catalog to C:\Drivers"
                    Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers' -PNPClass 'Net'
                }
                if ($OSDCloud.MSCatalogScsiDrivers) {
                    Write-Host -ForegroundColor DarkGray "Drivers for PNPClass SCSIAdapter will be downloaded from Microsoft Update Catalog to C:\Drivers"
                    Save-MsUpCatDriver -DestinationDirectory 'C:\Drivers' -PNPClass 'SCSIAdapter'
                }
            }
        }
    }
    #endregion
    #=================================================
    #   Add-OfflineServicingWindowsDriver
    #=================================================
    Write-SectionHeader "Add Windows Driver with Offline Servicing (Add-OfflineServicingWindowsDriver)"
    Write-Verbose -Message "https://docs.microsoft.com/en-us/powershell/module/dism/add-windowsdriver"
    Write-Host -ForegroundColor DarkGray "Drivers in C:\Drivers are being added to the offline Windows Image"
    Write-Host -ForegroundColor DarkGray "This process can take up to 20 minutes"
    Write-Verbose -Message "Add-OfflineServicingWindowsDriver"
    if ($Global:OSDCloud.Test -eq $false) {
        Add-OfflineServicingWindowsDriver
    }
    #=================================================
    #   Set-OSDCloudUnattendSpecialize
    #=================================================
    Write-SectionHeader "Set Specialize Unattend.xml (Set-OSDCloudUnattendSpecialize)"
    Write-Host -ForegroundColor DarkGray "C:\Windows\Panther\Invoke-OSDSpecialize.xml is being applied as an Unattend file"
    Write-Host -ForegroundColor DarkGray "This will enable the extraction and installation of HP, Lenovo, and Microsoft Surface Drivers if necessary"
    Write-Verbose -Message "Set-OSDCloudUnattendSpecialize"
    if ($Global:OSDCloud.Test -eq $false) {
        Set-OSDCloudUnattendSpecialize
        #Set-OSDxCloudUnattendSpecialize -Verbose
    }
    #=================================================
    #   HP Updates Config for Specialize Phase
    #=================================================
    #Set Specialize JSON
    if (($Global:OSDCloud.HPIAAll -eq $true) -or ($Global:OSDCloud.HPIADrivers -eq $true) -or ($Global:OSDCloud.HPIAFirmware -eq $true) -or ($Global:OSDCloud.HPIASoftware -eq $true) -or ($Global:OSDCloud.HPTPMUpdate -eq $true) -or ($Global:OSDCloud.HPBIOSUpdate -eq $true)){
        $HPFeaturesEnabled = $true
        Write-Host -ForegroundColor Cyan "Adding HP Tasks into JSON Config File for Action during Specialize" 
        Write-Host -ForegroundColor DarkGray "HPIA Drivers = $($Global:OSDCloud.HPIADrivers) | HPIA Firmware = $($Global:OSDCloud.HPIAFirmware) | HPIA Software = $($Global:OSDCloud.HPIADrivers) | HPIA All = $($Global:OSDCloud.HPIAFirmware) "
        Write-Host -ForegroundColor DarkGray "HP TPM Update = $($Global:OSDCloud.HPTPMUpdate) | HP BIOS Update = $($Global:OSDCloud.HPBIOSUpdate)" 
        $HPHashTable = @{
            'HPUpdates' = @{
                'HPIADrivers' = $Global:OSDCloud.HPIADrivers
                'HPIAFirmware' = $Global:OSDCloud.HPIAFirmware
                'HPIASoftware' = $Global:OSDCloud.HPIASoftware
                'HPIAAll' = $Global:OSDCloud.HPIAALL
                'HPTPMUpdate' = $Global:OSDCloud.HPTPMUpdate
                'HPBIOSUpdate' = $Global:OSDCloud.HPBIOSUpdate
            }
        }
        $HPHashVar = $HPHashTable | ConvertTo-Json
        $ConfigPath = "c:\osdcloud\configs"
        $ConfigFile = "$ConfigPath\HP.JSON"
        try {[void][System.IO.Directory]::CreateDirectory($ConfigPath)}
        catch {}
        $HPHashVar | Out-File $ConfigFile
        osdcloud-downloadHPIA
    }
    <#
    #Stage Firmware Update for Next Reboot
    if ($Global:OSDCloud.HPBIOSUpdate -eq $true){
    Write-Host -ForegroundColor Cyan "Updating HP System Firmware"
    if (Get-HPBIOSSetupPasswordIsSet){Write-Host -ForegroundColor Red "Device currently has BIOS Setup Password, Please Update BIOS via different method"}
    else{
        Write-Host -ForegroundColor DarkGray "Current Firmware: $(Get-HPBIOSVersion)"
        Write-Host -ForegroundColor DarkGray "Staging Update: $((Get-HPBIOSUpdates -Latest).ver) "
        #Details: https://developers.hp.com/hp-client-management/doc/Get-HPBiosUpdates
        Get-HPBIOSUpdates -Flash -Yes -Offline -BitLocker Ignore
        }
    }
    #>
    if ($Global:OSDCloud.HPTPMUpdate -eq $true){
        osdcloud-SetTPMBIOSSettings
        osdcloud-DownloadHPTPMEXE
    }   
    #=================================================
    #Leverage SetupComplete.cmd to run HP Tools
    $ScriptsPath = "C:\Windows\Setup\scripts"
    if (!(Test-Path -Path $ScriptsPath)){New-Item -Path $ScriptsPath} 
    
    $RunScriptTable = @(
        @{ Script = "SetupComplete"; BatFile = 'SetupComplete.cmd'; ps1file = 'SetupComplete.ps1';Type = 'Setup'; Path = "$ScriptsPath"}
    )
    
    ForEach ($RunScript in $RunScriptTable)
        {
        Write-Output $RunScript.Script
    
        $BatFilePath = "$($RunScript.Path)\$($RunScript.batFile)"
        $PSFilePath = "$($RunScript.Path)\$($RunScript.ps1File)"
            
        #Create Batch File to Call PowerShell File
            
        New-Item -Path $BatFilePath -ItemType File -Force
        $CustomActionContent = New-Object system.text.stringbuilder
        [void]$CustomActionContent.Append('%windir%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File')
        [void]$CustomActionContent.Append(" $PSFilePath")
        Add-Content -Path $BatFilePath -Value $CustomActionContent.ToString()
    
        #Create PowerShell File to do actions
            
        New-Item -Path $PSFilePath -ItemType File -Force
        Add-Content -path $PSFilePath "Set-ExecutionPolicy Bypass -Force | out-null"
        Add-Content -Path $PSFilePath "Start-Transcript -Path 'C:\OSDCloud\Logs\SetupComplete.log' -ErrorAction Ignore"
        Add-Content -Path $PSFilePath "Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/deviceshp.psm1')"
        Add-Content -Path $PSFilePath "Invoke-Expression (Invoke-RestMethod -Uri 'functions.osdcloud.com' -ErrorAction SilentlyContinue)"
        Add-Content -Path $PSFilePath "osdcloud-InstallModuleHPCMSL -ErrorAction SilentlyContinue"
        Add-Content -Path $PSFilePath 'Write-Host "Running HP Tools in SetupComplete" -ForegroundColor Green'
        if (($Global:OSDCloud.HPIADrivers -eq $true) -and ($Global:OSDCloud.HPIAAll -ne $true)){
            Add-Content -Path $PSFilePath 'Write-Host "Running HPIA for Drivers" -ForegroundColor Magenta'
            Add-Content -Path $PSFilePath "osdcloud-RunHPIA -Category Drivers"
        }
        if (($Global:OSDCloud.HPIAFirmware -eq $true) -and ($Global:OSDCloud.HPIAAll  -ne $true)){
            Add-Content -Path $PSFilePath 'Write-Host "Running HPIA for Firmware" -ForegroundColor Magenta'
            Add-Content -Path $PSFilePath "osdcloud-RunHPIA -Category Firmware"
        } 
        if (($Global:OSDCloud.HPIASoftware -eq $true) -and ($Global:OSDCloud.HPIAAll  -ne $true)){
            Add-Content -Path $PSFilePath 'Write-Host "Running HPIA for Software" -ForegroundColor Magenta'
            Add-Content -Path $PSFilePath "osdcloud-RunHPIA -Category Software"
        } 
        if ($Global:OSDCloud.HPIAAll -eq $true){
            Add-Content -Path $PSFilePath 'Write-Host "Running HPIA for Software" -ForegroundColor Magenta'
            Add-Content -Path $PSFilePath "osdcloud-RunHPIA -Category All"
        }            
        if ($Global:OSDCloud.HPTPMUpdate -eq $true){
            #Add-Content -Path $PSFilePath 'Write-Host "Updating TPM Firmware" -ForegroundColor Magenta'
            #Add-Content -Path $PSFilePath "osdcloud-InstallTPMEXE"
        } 
        if ($Global:OSDCloud.HPBIOSUpdate -eq $true){
            Add-Content -Path $PSFilePath 'Write-Host "Running HP System Firmware" -ForegroundColor Magenta'
            Add-Content -Path $PSFilePath "osdcloud-UpdateHPBIOS"
        }
        Add-Content -Path $PSFilePath "Stop-Transcript"
        Add-Content -Path $PSFilePath "Restart-Computer -Force"
    }


    #=================================================
    #   AutopilotConfigurationFile.json
    #=================================================
    if ($Global:OSDCloud.AutopilotJsonObject) {
        Write-SectionHeader "Applying AutopilotConfigurationFile.json"
        Write-Host -ForegroundColor DarkGray 'C:\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json'
        $Global:OSDCloud.AutopilotJsonObject | ConvertTo-Json | Out-File -FilePath 'C:\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json' -Encoding ascii -Width 2000 -Force
    }
    #=================================================
    #   OSDeploy.OOBEDeploy.json
    #=================================================
    if ($Global:OSDCloud.OOBEDeployJsonObject) {
        Write-SectionHeader "Applying OSDeploy.OOBEDeploy.json"
        Write-Host -ForegroundColor DarkGray 'C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json'

        If (!(Test-Path "C:\ProgramData\OSDeploy")) {
            New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
        }
        $Global:OSDCloud.OOBEDeployJsonObject | ConvertTo-Json | Out-File -FilePath 'C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json' -Encoding ascii -Width 2000 -Force
        #================================================
        #   WinPE PostOS
        #   Set OOBEDeploy CMD.ps1
        #================================================
$SetCommand = @'
@echo off

:: Set the PowerShell Execution Policy
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force

:: Add PowerShell Scripts to the Path
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts

:: Open and Minimize a PowerShell instance just in case
start PowerShell -NoL -W Mi

:: Install the latest OSD Module
start "Install-Module OSD" /wait PowerShell -NoL -C Install-Module OSD -Force -Verbose

:: Start-OOBEDeploy
:: The next line assumes that you have a configuration saved in C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy

exit
'@
        $SetCommand | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Width 2000 -Force
    }
    #=================================================
    #   OSDeploy.AutopilotOOBE.json
    #=================================================
    if ($Global:OSDCloud.AutopilotOOBEJsonObject) {
        Write-SectionHeader "Applying OSDeploy.AutopilotOOBE.json"
        Write-Host -ForegroundColor DarkGray 'C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json'

        If (!(Test-Path "C:\ProgramData\OSDeploy")) {
            New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
        }
        $Global:OSDCloud.AutopilotOOBEJsonObject | ConvertTo-Json | Out-File -FilePath 'C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json' -Encoding ascii -Width 2000 -Force
    }
    #=================================================
    #   Stage Office Config
    #=================================================
    if ($Global:OSDCloud.ODTFile) {
        Write-SectionHeader "Stage Office Config"

        if (!(Test-Path $Global:OSDCloud.ODTTarget)) {
            New-Item -Path $Global:OSDCloud.ODTTarget -ItemType Directory -Force | Out-Null
        }

        if (Test-Path $Global:OSDCloud.ODTFile.FullName) {
            Copy-Item -Path $Global:OSDCloud.ODTFile.FullName -Destination $Global:OSDCloud.ODTConfigFile -Force
        }

        $Global:OSDCloud.ODTSetupFile = Join-Path $Global:OSDCloud.ODTFile.Directory 'setup.exe'
        Write-Verbose -Verbose "ODTSetupFile: $($Global:OSDCloud.ODTSetupFile)"
        if (Test-Path $Global:OSDCloud.ODTSetupFile) {
            Copy-Item -Path $Global:OSDCloud.ODTSetupFile -Destination $Global:OSDCloud.ODTTarget -Force
        }

        $Global:OSDCloud.ODTSource = Join-Path $Global:OSDCloud.ODTFile.Directory 'Office'
        Write-Verbose -Verbose "ODTSource: $($Global:OSDCloud.ODTSource)"
        if (Test-Path $Global:OSDCloud.ODTSource) {
            Invoke-Exe robocopy "$($Global:OSDCloud.ODTSource)" "$($Global:OSDCloud.ODTTargetData)" *.* /s /ndl /nfl /z /b
        }
    }
    #=================================================
    #   Save PowerShell Modules to OSDisk
    #=================================================
    Write-SectionHeader "Saving PowerShell Modules and Scripts"
    if ($Global:OSDCloud.Test -eq $false) {
        $PowerShellSavePath = 'C:\Program Files\WindowsPowerShell'

        if (-NOT (Test-Path "$PowerShellSavePath\Configuration")) {
            New-Item -Path "$PowerShellSavePath\Configuration" -ItemType Directory -Force | Out-Null
        }
        if (-NOT (Test-Path "$PowerShellSavePath\Modules")) {
            New-Item -Path "$PowerShellSavePath\Modules" -ItemType Directory -Force | Out-Null
        }
        if (-NOT (Test-Path "$PowerShellSavePath\Scripts")) {
            New-Item -Path "$PowerShellSavePath\Scripts" -ItemType Directory -Force | Out-Null
        }
        
        if (Test-WebConnection -Uri "https://www.powershellgallery.com") {
            Copy-PSModuleToFolder -Name OSD -Destination "$PowerShellSavePath\Modules"

            try {
                Save-Module -Name OSD -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module OSD to $PowerShellSavePath\Modules"
            }

            try {
                Save-Module -Name PackageManagement -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module PackageManagement to $PowerShellSavePath\Modules"
            }

            try {
                Save-Module -Name PowerShellGet -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module PowerShellGet to $PowerShellSavePath\Modules"
            }

            try {
                Save-Module -Name WindowsAutopilotIntune -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module WindowsAutopilotIntune to $PowerShellSavePath\Modules"
            }

            try {
                Save-Script -Name Get-WindowsAutopilotInfo -Path "$PowerShellSavePath\Scripts" -ErrorAction Stop
            }
            catch {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Script Get-WindowsAutopilotInfo to $PowerShellSavePath\Scripts"
            }
            if ($HPFeaturesEnabled){
                try {
                    Save-Module -Name HPCMSL -AcceptLicense -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
                }
                catch {
                    Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Unable to Save-Module HPCMSL to $PowerShellSavePath\Modules"
                }
            }
        }
        else {
            Write-Verbose -Verbose "Copy-PSModuleToFolder -Name OSD to $PowerShellSavePath\Modules"
            Copy-PSModuleToFolder -Name OSD -Destination "$PowerShellSavePath\Modules"
            Copy-PSModuleToFolder -Name PackageManagement -Destination "$PowerShellSavePath\Modules"
            Copy-PSModuleToFolder -Name PowerShellGet -Destination "$PowerShellSavePath\Modules"
            Copy-PSModuleToFolder -Name WindowsAutopilotIntune -Destination "$PowerShellSavePath\Modules"
            if ($HPFeaturesEnabled){Copy-PSModuleToFolder -Name HPCMSL -Destination "$PowerShellSavePath\Modules"}
            $OSDCloudOfflinePath = Find-OSDCloudOfflinePath
        
            foreach ($Item in $OSDCloudOfflinePath) {
                if (Test-Path "$($Item.FullName)\PowerShell\Required") {
                    Write-Host -ForegroundColor Cyan "Applying PowerShell Modules and Scripts in $($Item.FullName)\PowerShell\Required"
                    robocopy "$($Item.FullName)\PowerShell\Required" "$PowerShellSavePath" *.* /s /ndl /njh /njs
                }
            }
        }
    }

    #=================================================
    #   Debug Mode
    #=================================================
    if ($Global:OSDCloud.DebugMode -eq $true){
        Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/debugmode.psm1')
        osdcloud-addcmtrace
        osdcloud-addmouseoobe
        osdcloud-UpdateModuleFilesManually
    }
    #=================================================
    #	Deploy-OSDCloud Complete
    #=================================================
    $Global:OSDCloud.TimeEnd = Get-Date
    $Global:OSDCloud.TimeSpan = New-TimeSpan -Start $Global:OSDCloud.TimeStart -End $Global:OSDCloud.TimeEnd
    
    $Global:OSDCloud | ConvertTo-Json | Out-File -FilePath 'C:\OSDCloud\Logs\OSDCloud.json' -Encoding ascii -Width 2000 -Force
    Write-SectionHeader "OSDCloud Finished"
    Write-Host -ForegroundColor DarkGray "Completed in $($Global:OSDCloud.TimeSpan.ToString("mm' minutes 'ss' seconds'"))"
    #=================================================
    if ($Global:OSDCloud.Screenshot) {
        Start-Sleep 5
        Stop-ScreenPNGProcess
        Write-Host -ForegroundColor DarkGray "Screenshots: $($Global:OSDCloud.Screenshot)"
    }
    #=================================================
    if ($Global:OSDCloud.Restart) {
        Write-Warning "WinPE is restarting in 30 seconds"
        Write-Warning "Press CTRL + C to cancel"
        Start-Sleep -Seconds 30
        if ($Global:OSDCloud.Test -eq $false) {
            Restart-Computer
        }
    }
    #=================================================
    if ($Global:OSDCloud.Shutdown) {
        Write-Warning "WinPE will shutdown in 30 seconds"
        Write-Warning "Press CTRL + C to cancel"
        Start-Sleep -Seconds 30
        if ($Global:OSDCloud.Test -eq $false) {
            Stop-Computer
        }
    }
    #=================================================
    #	Stop-Transcript
    #=================================================
    if ($OSDCloud.Test -eq $true) {
        Stop-Transcript
    }
    #=================================================
}
##########################################################################
###################### END OSDCLOUD INVOKE ###############################
##########################################################################






















#Start OSDCloud ZTI the RIGHT way
Write-Host  -ForegroundColor Cyan "Start OSDCloud with Marshfield Parameters"
Start-OSDCloudMFLD -ImageFileUrl $wimUrl -ZTI 
#Start-OSDCloudMFLD -OSVersion $mfldwinver -OSLanguage en-us -OSBuild 21H2 -OSEdition Education -ZTI

##########################################################################
###################### START UPDATE DELL BIOS  ###########################
##########################################################################

if ((Get-MyComputerManufacturer -Brief) -eq "Dell" -and $password) {
    #Set BIOS Root Path
    $path = 'C:\Drivers\BIOS'
    #======================================================================================
    #Get System Information
    $global:Manufacturer = $((Get-WmiObject -Class Win32_ComputerSystem).Manufacturer).Trim()
    $Model = $((Get-WmiObject -Class Win32_ComputerSystem).Model).Trim()
    try {$SystemSKU = $((Get-WmiObject -Class Win32_ComputerSystem).SystemSKUNumber).Trim()}
    catch {$SystemSKU = "Unknown"}
    $SerialNumber = $((Get-WmiObject -Class Win32_BIOS).SerialNumber).Trim()
    [Version]$BIOSVersion = $((Get-WmiObject -Class Win32_BIOS).SMBIOSBIOSVersion).Trim()
    $RunningOS = $((Get-WmiObject -Class Win32_OperatingSystem).Caption).Trim()
    $OSArchitecture = $((Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture).Trim()

    Write-Host "Manufacturer: $Manufacturer" -ForegroundColor Cyan
    Write-Host "Model: $Model" -ForegroundColor Cyan
    Write-Host "SystemSKU: $SystemSKU" -ForegroundColor Cyan
    Write-Host "SerialNumber: $SerialNumber" -ForegroundColor Cyan
    Write-Host "BIOS Version: $BIOSVersion" -ForegroundColor Cyan
    Write-Host "Running OS: $RunningOS" -ForegroundColor Cyan
    Write-Host "OS Architecture: $OSArchitecture" -ForegroundColor Cyan
    if ($env:SystemDrive -eq "X:") {Write-Host "System is running in WinPE" -ForegroundColor Green}
    #======================================================================================
    #Create Folders if needed
    $DellBiosRoot = $Path
    $DellBiosBin = Join-Path $DellBiosRoot "Bin"
    New-Item -Path $DellBiosBin -ItemType Directory
    #======================================================================================
    #Set Dell Catalog Location
    $DellDownloadsUrl = "http://downloads.dell.com/"
    $DellCatalogPcUrl = "http://downloads.dell.com/catalog/CatalogPC.cab"
    $DellCatalogPcCab = Join-Path $DellBiosBin ($DellCatalogPcUrl | Split-Path -Leaf)
    $DellCatalogPcXml = Join-Path $DellBiosBin "CatalogPC.xml"
    #======================================================================================
    #Download Cab File from Dell
    Write-Host "Downloading $DellCatalogPcUrl ..." -ForegroundColor Green
    try {
        Invoke-WebRequest $DellCatalogPcUrl -OutFile $DellCatalogPcCab
    } catch { 
        Write-Host "Download Failed!" -ForegroundColor Red
    }
    #======================================================================================
    #Expand the Cab File
    if (Test-Path $DellCatalogPcCab ) {
        Write-Host "Unblocking $DellCatalogPcCab ..." -ForegroundColor Green
        Unblock-File -Path $DellCatalogPcCab
        Start-Sleep -s 1
        Write-Host "Expanding $DellCatalogPcCab ..." -ForegroundColor Green
        Expand "$DellCatalogPcCab" "$DellCatalogPcXml" | Out-String | Write-Host
    }
    #======================================================================================
    #If Cab XML file does not exist, exit
    if (!( test-path $DellCatalogPcXml)) { 
        Write-Host "Could not expand required Dell Update Catalog ... Exiting" -ForegroundColor Red
        Return
    }
    #======================================================================================
    #Get XML File and filter to Only BIOS Updates
    Write-Host "Reading $DellCatalogPcXml ..." -ForegroundColor Green
    [xml]$XMLDellUpdateCatalog = Get-Content "$DellCatalogPcXml" -ErrorAction Stop

    Write-Host "Loading Dell Update Catalog XML Nodes ..." -ForegroundColor Green
    $DellUpdateList = $XMLDellUpdateCatalog.Manifest.SoftwareComponent

    Write-Host "Filtering Dell Update Catalog XML for BIOS Downloads ..." -ForegroundColor Green
    $DellUpdateList = $DellUpdateList | Where-Object {$_.ComponentType.Display.'#cdata-section' -eq 'BIOS'}

    #======================================================================================
    #Put XML into readable format.  This makes it easier to parse
    Write-Host "Generating Update List Array ..." -ForegroundColor Green
    $DellUpdateList = $DellUpdateList | Select-Object @{Label="ReleaseDate";Expression = {[datetime] ($_.dateTime)};},
    @{Label="Downloaded";Expression = {($DownloadedFiles.Name -Contains (split-path -leaf $_.path))};},
    @{Label="PackageGroup";Expression={"Undefined"};},
    @{Label="BiosGroup";Expression={($_.SupportedDevices.Device.Display.'#cdata-section'.Trim() -replace "PRECISION","Precision" -replace "Dell ","" -replace " "," ")};},
    @{Label="FileName";Expression = {(split-path -leaf $_.path)};},
    @{Label="DellVersion";Expression={$_.dellVersion};},
    @{Label="Size(MB)";Expression={'{0:f2}' -f ($_.size/1MB)};},
    @{Label="PackageID";Expression={$_.packageID};},
    @{Label="Name";Expression={($_.Name.Display.'#cdata-section'.Trim())};},
    @{Label="SupportedBrand";Expression={($_.SupportedSystems.Brand.Display.'#cdata-section'.Trim())};},
    @{Label="SupportedModel";Expression={($_.SupportedSystems.Brand.Model.Display.'#cdata-section'.Trim() | Select-Object -unique)};},
    @{Label="SupportedSystemID";Expression={($_.SupportedSystems.Brand.Model.systemID.Trim() | Select-Object -unique)};},
    @{Label="DownloadURL";Expression={-join ($DellDownloadsUrl, $_.path)};}
    #======================================================================================
    #Remove T0N11 32
    $DellUpdateList = $DellUpdateList | Where-Object {$_.DownloadURL -NotLike "*WN32*"}

    #Get the most recent bios update
    $DellUpdateFile = $DellUpdateList | Where-Object {$_.SupportedSystemID -Contains $SystemSKU} | Sort-Object ReleaseDate -Descending | Select-Object -First 1

    #If the most recent bios update is newer than installed, continue.
    if ([Version]$DellUpdateFile.DellVersion -gt [Version]$BIOSVersion) {
        #======================================================================================
        #Download Flash64W from github
        $DellFlash64wUrl = 'https://raw.githubusercontent.com/cattanach-mfld/osdzti/main/Flash64W.exe'
        $DellFlash64wExe = Join-Path $DellBiosRoot "Flash64W.exe"
        #======================================================================================
        Write-Host "Downloading $DellFlash64wUrl ..." -ForegroundColor Green
        try {
            Invoke-WebRequest $DellFlash64wUrl -OutFile $DellFlash64wExe
        } catch { 
            Write-Host "Download Failed!" -ForegroundColor Red
        }

        #Download BIOS Update
        $SourceFile = $DellUpdateFile.DownloadURL.Trim()
        Write-Host "Downloading: $SourceFile" -ForegroundColor Green

        $DownloadFile = Join-Path $DellBiosRoot (split-path -leaf $DellUpdateFile.DownloadURL.Trim())
        Invoke-WebRequest $SourceFile -OutFile $DownloadFile
        
        #If download file exists, run it
        if (Test-Path $DownloadFile) {
            Write-Host "Executing (Silent): $DellFlash64wExe /b=`"$DownloadFile`"" -ForegroundColor Green
            Start-Process -FilePath $DellFlash64wExe -ArgumentList "/b=`"$DownloadFile`"","/s","/f","/p=`"$password`"" -Wait
        }
    } else {
        Write-Host "BIOS is already current.  No Need to update."
    }
}

##########################################################################
###################### END UPDATE DELL BIOS ##############################
##########################################################################

#Removing OS Files
if (Test-Path "C:\OSDCloud\OS") {
    Remove-Item "C:\OSDCloud\OS" -Recurse -Force
}

#Remove the USB Drive so that it can reboot properly
if (Get-Volume.usb) {
    Write-Warning "Press Remove Flash Drive"
    while (Get-Volume.usb) {
        Start-Sleep -Seconds 2
    }
}

#Restart from WinPE
wpeutil reboot
