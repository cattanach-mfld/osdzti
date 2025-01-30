Write-Host -ForegroundColor Cyan "Starting Marshfield's Custom OSDCloud ..."


# Set OSDCloud Defaults
$Global:MyOSDCloud = [ordered]@{
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$true
    WindowsUpdateDrivers = [bool]$false
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$true
}

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

#Remove the USB Drive so that it can reboot properly
if (Get-Volume.usb) {
    Write-Warning "Please Remove Flash Drive"
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













#Start OSDCloud ZTI the RIGHT way
Write-Host  -ForegroundColor Cyan "Start OSDCloud with Marshfield Parameters"
#Start-OSDCloud -ImageFileUrl $wimUrl -ZTI
#Start-OSDCloudMFLD -OSVersion "Windows 11" -OSLanguage en-us -OSBuild 22H2 -OSEdition Education -ZTI
Start-OSDCloud -OSVersion "Windows 11" -OSLanguage en-us -OSBuild 24H2 -OSEdition Education -ZTI

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
    Write-Warning "Please Remove Flash Drive"
    while (Get-Volume.usb) {
        Start-Sleep -Seconds 2
    }
}

#Restart from WinPE
wpeutil reboot
