# Changer les valeurs en fonction de votre environnement.
$Source_VM_Disk_VirtualBox = 'D:\2020 Storm\VirtualBox VMs\OVA_virtual_lab'
$Destiantion_VM_Workstation = 'D:\Virtual Machines'
$ExportPath = 'D:\Virtual Machines'
$Destination_OVA_VMware = 'D:\'
Import-Module '.\vmxtoolkit\4.5.3.1\vmxtoolkit.psm1'
$ScenarioName = "StormLab"
################## Some Globals don't Touch ###################
if ($PSVersionTable.PSVersion -lt [version]"6.0.0") {
    Write-Verbose "this will check if we are on 6"
}
write-Host "trying to get os type ... "
if ($env:windir) {
    $OS_Version = Get-Command "$env:windir\system32\ntdll.dll"
    $OS_Version = "Product Name: Windows $($OS_Version.Version)"
    $Global:vmxtoolkit_type = "win_x86_64"
    write-verbose "getting VMware Path from Registry"
    if (!(Test-Path "HKCR:\")) { $NewPSDrive = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT }
    if (!($VMware_Path = Get-ItemProperty HKCR:\Applications\vmware.exe\shell\open\command -ErrorAction SilentlyContinue)) {
        Write-Error "VMware Binaries not found from registry"
        Break
    }

    $preferences_file = "$env:AppData\VMware\preferences.ini"
    $VMX_BasePath = '\Documents\Virtual Machines\'	
    $VMware_Path = Split-Path $VMware_Path.'(default)' -Parent
    $VMware_Path = $VMware_Path -replace '"', ''
    $Global:vmwarepath = $VMware_Path
    $Global:vmware = "$VMware_Path\vmware.exe"
    $Global:vmrun = "$VMware_Path\vmrun.exe"
    $Global:vmware_vdiskmanager = Join-Path $VMware_Path 'vmware-vdiskmanager.exe'
    $Global:VMware_OVFTool = Join-Path $Global:vmwarepath 'OVFTool\ovftool.exe'
    $GLobal:VMware_packer = Join-Path $Global:vmwarepath '7za.exe'
    $VMwarefileinfo = Get-ChildItem $Global:vmware
    $Global:vmxinventory = "$env:appdata\vmware\inventory.vmls"
    $Global:vmwareversion = New-Object System.Version($VMwarefileinfo.VersionInfo.ProductMajorPart, $VMwarefileinfo.VersionInfo.ProductMinorPart, $VMwarefileinfo.VersionInfo.ProductBuildPart, $VMwarefileinfo.VersionInfo.ProductVersion.Split("-")[1])
    $webrequestor = ".Net"
    $Global:mkisofs = "$Global:vmwarepath/mkisofs.exe"
}
elseif ($OS = uname) {
    Write-Host "found OS $OS"
    Switch ($OS) {
        "Darwin" {
            $Global:vmxtoolkit_type = "OSX"
            $OS_Version = (sw_vers)
            $OS_Version = $OS_Version -join " "
            $VMX_BasePath = 'Documents/Virtual Machines.localized'
            # $VMware_Path = "/Applications/VMware Fusion.app"
            $VMware_Path = mdfind -onlyin /Applications "VMware Fusion"                
            $Global:vmwarepath = $VMware_Path
            [version]$Fusion_Version = defaults read $VMware_Path/Contents/Info.plist CFBundleShortVersionString
            $VMware_BIN_Path = Join-Path $VMware_Path  '/Contents/Library'
            $preferences_file = "$HOME/Library/Preferences/VMware Fusion/preferences"
            try {
                $webrequestor = (get-command curl).Path
            }
            catch {
                Write-Warning "curl not found"
                exit
            }
            try {
                $GLobal:VMware_packer = (get-command 7za -ErrorAction Stop).Path 
            }
            catch {
                Write-Warning "7za not found, pleas install p7zip full"
                Break
            }

            $Global:VMware_vdiskmanager = Join-Path $VMware_BIN_Path 'vmware-vdiskmanager'
            $Global:vmrun = Join-Path $VMware_BIN_Path "vmrun"
            switch ($Fusion_Version.Major) {
                "10" {
                    $Global:VMware_OVFTool = "/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool"
                    [version]$Global:vmwareversion = "14.0.0.0"
                }
					
                default {
                    $Global:VMware_OVFTool = Join-Path $VMware_Path 'ovftool'
                    [version]$Global:vmwareversion = "12.0.0.0"
                }
            }

        }
        'Linux' {
            $Global:vmxtoolkit_type = "LINUX"
            $OS_Version = (uname -o)
            #$OS_Version = $OS_Version -join " "
            $preferences_file = "$HOME/.vmware/preferences"
            $VMX_BasePath = '/var/lib/vmware/Shared VMs'
            try {
                $webrequestor = (get-command curl).Path
            }
            catch {
                Write-Warning "curl not found"
                exit
            }
            try {
                $VMware_Path = Split-Path -Parent (get-command vmware).Path
            }
            catch {
                Write-Warning "VMware Path not found"
                exit
            }

            $Global:vmwarepath = $VMware_Path
            $VMware_BIN_Path = $VMware_Path  
            try {
                $Global:VMware_vdiskmanager = (get-command vmware-vdiskmanager).Path
            }
            catch {
                Write-Warning "vmware-vdiskmanager not found"
                break
            }
            try {
                $GLobal:VMware_packer = (get-command 7za).Path
            }
            catch {
                Write-Warning "7za not found, pleas install p7zip full"
            }
				
            try {
                $Global:vmrun = (Get-Command vmrun).Path
            }	
            catch {
                Write-Warning "vmrun not found"
                break
            }
            try {
                $Global:VMware_OVFTool = (Get-Command ovftool).Path
            }
            catch {
                Write-Warning "ovftool not found"
                break
            }
            try {
                $Global:mkisofs = (Get-Command mkisofs).Path
            }
            catch {
                Write-Warning "mkisofs not found"
                break
            }
            $Vmware_Base_Version = (vmware -v)
            $Vmware_Base_Version = $Vmware_Base_Version -replace "VMware Workstation "
            [version]$Global:vmwareversion = ($Vmware_Base_Version.Split(' '))[0]
        }
        default {
            Write-host "Sorry, rome was not build in one day"
            exit
        }
			
			
			
        'default' {
            write-host "unknown linux OS"
            break
        }
    }
}
else {
    write-host "error detecting OS"
}

if (Test-Path $preferences_file) {
        Write-Verbose "Found VMware Preferences file"
        Write-Verbose "trying to get vmx path from preferences"
        $defaultVMPath = get-content $preferences_file | Select-String prefvmx.defaultVMPath
        if ($defaultVMPath) {
            $defaultVMPath = $defaultVMPath -replace "`""
            $defaultVMPath = ($defaultVMPath -split "=")[-1]
            $defaultVMPath = $defaultVMPath.TrimStart(" ")
            Write-Verbose "default vmpath from preferences is $defaultVMPath"
            $VMX_default_Path = $defaultVMPath
            $defaultselection = "preferences"
        }
        else {
            Write-Verbose "no defaultVMPath in prefernces"
        }
    }

if (!$VMX_Path) {
    if (!$VMX_default_Path) {
        Write-Verbose "trying to use default vmxdir in homedirectory" 
        try {
            $defaultselection = "homedir"
            $Global:vmxdir = Join-Path $HOME $VMX_BasePath
        }
        catch {
            Write-Warning "could not evaluate default Virtula machines home, using $PSScriptRoot"
            $Global:vmxdir = $PSScriptRoot
            $defaultselection = "ScriptRoot"
            Write-Verbose "using psscriptroot as vmxdir"
        }
		
    }
    else {
        if (Test-Path $VMX_default_Path) {
            $Global:vmxdir = $VMX_default_Path	
        }
        else {
            $Global:vmxdir = $PSScriptRoot
        }
		
    }
}
else {
    $Global:vmxdir = $VMX_Path
}

#### some vmx api error handlers :-) false positives from experience
$Global:VMrunErrorCondition = @(
    "Waiting for Command execution Available",
    "Error",
    "Unable to connect to host.",
    "Error: Unable to connect to host.",
    "Error: The operation is not supported for the specified parameters",
    "Unable to connect to host. Error: The operation is not supported for the specified parameters",
    "Error: The operation is not supported for the specified parameters",
    "Error: vmrun was unable to start. Please make sure that vmrun is installed correctly and that you have enough resources available on your system.",
    "Error: The specified guest user must be logged in interactively to perform this operation",
    "Error: A file was not found",
    "Error: VMware Tools are not running in the guest",
    "Error: The VMware Tools are not running in the virtual machine" )
if (!$GLobal:VMware_packer) {
    Write-Warning "Please install 7za/p7zip, otherwise labbtools can not expand OS Masters"
}
if ($OS_Version) {
    write-Host -ForegroundColor Gray " ==>$OS_Version"
}
else	{
    write-host "error Detecting OS"
    Break
}
Write-Host -ForegroundColor Gray " ==>running vmxtoolkit for $Global:vmxtoolkit_type"
Write-Host -ForegroundColor Gray " ==>vmrun is $Global:vmrun"
Write-Host -ForegroundColor Gray " ==>vmwarepath is $Global:vmwarepath"
if ($VMX_Path) {
    Write-Host -ForegroundColor Gray " ==>using virtual machine directory from module load $Global:vmxdir"
}
else {
    Write-Host -ForegroundColor Gray " ==>using virtual machine directory from $defaultselection`: $Global:vmxdir"
}	
<# Size for openstack compute nodes
        'XS'  = 1vCPU, 512MB
        'S'   = 1vCPU, 768MB
        'M'   = 1vCPU, 1024MB
        'L'   = 2vCPU, 2048MB
        'XL'  = 2vCPU, 4096MB
        'TXL' = 4vCPU, 6144MB
        'XXL' = 4vCPU, 8192MB
        #>

################## Some Globals don't Touch ###################

function New-StormShieldLabStudents {
    
    begin {
        [Int]$StudentPack = 1
        $Trainee = ("Debian-Training-WebMail", "SNS_EVA1_V4")
        $Sites = @("A";"B")

    }
    
    process {
        for ($i = 0; $i -le $StudentPack; $i++) {
    
            foreach ($item in $Trainee ) {
                
                foreach ($Site in $Sites) {
                    
                        $VMname = 'T'+ "$Site`_" + $item
                        
                        switch ($item)
                        {
                            'Debian-Training-WebMail' 
                            {
                                $disk ="Appareil virtuel (appliance)-disk002.vmdk"
                                $GuestOs = 'debian10' 
                            }
                            'SNS_EVA1_V4'             
                            {
                                $disk ="Appareil virtuel (appliance)-disk001.vmdk"
                                $GuestOs = 'freeBSD-64'
                            }
                        }
                        New-VMX -VMXName $VMname -GuestOS $GuestOs -Firmware BIOS -Path $Destiantion_VM_Workstation |Out-Null
                        Set-VMXDisplayName -DisplayName $VMname -config  "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" |Out-Null
                        Copy-Item -Path "$Source_VM_Disk_VirtualBox\$item\$disk" -Destination "$Destiantion_VM_Workstation\$VMname\$VMname.vmdk" |Out-Null
                        Add-VMXScsiDisk -Diskname "$Destiantion_VM_Workstation\$VMname\$VMname.vmdk"`
                        -VMXName $VMname -config   "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" -LUN 1 -Controller 0 |Out-Null                
                }
            }
        }
    }
    
    end {
        $VMs = get-VMX -Path $Destiantion_VM_Workstation
        $VMlab=@()
        foreach ($item in $VMs) {

        if ($item.VMXName -like "T*Debian-Training-WebMail"){

            Write-Host $item.VMXName
            Set-VMXSize -VMXName $item.VMXName -Path  $Destiantion_VM_Workstation -config $item.Config -Size XS | Out-Null
            Set-VMXNetworkAdapter -VMXName $VMname.VMXName -config $item.Config -AdapterType vmxnet3 -Adapter 0 -ConnectionType bridged |Out-Null
            Set-VMXVnet -VMXName $VMname.VMXName -config $item.Config -Adapter 0 -Vnet VMnet4 -WarningAction SilentlyContinue |Out-Null
            Set-VMXScenario -VMXName $item.VMXName -config $item.Config -Scenario 1 -Scenarioname $ScenarioName

        }
        if ($item.VMXName -like "T*SNS_EVA1_V4"){

            Write-Host $item.VMXName
            Set-VMXSize -VMXName $item.VMXName -Path  $Destiantion_VM_Workstation -config   $item.Config -Size M | Out-Null
            Set-VMXNetworkAdapter -VMXName $item.VMXName -config $item.Config -AdapterType vmxnet3 -Adapter 0 -ConnectionType nat |Out-Null
            Set-VMXNetworkAdapter -VMXName $item.VMXName -config $item.Config -AdapterType vmxnet3 -Adapter 1 -ConnectionType bridged |Out-Null
            Set-VMXVnet -VMXName $item.VMXName -config $item.Config  -Adapter 1 -Vnet VMnet3 -WarningAction SilentlyContinue |Out-Null
            Set-VMXNetworkAdapter -VMXName $item.VMXName -config $item.Config -AdapterType vmxnet3 -Adapter 2 -ConnectionType bridged |Out-Null
            Set-VMXVnet -VMXName $item.VMXName  -config $item.Config -Adapter 2 -Vnet VMnet4 -WarningAction SilentlyContinue |Out-Null    
            Set-VMXScenario -VMXName $item.VMXName -config $item.Config -Scenario 1 -Scenarioname $ScenarioName

        }
        
        #Create a Scenario
        try {
        $test = Get-VMXscenario -VMXName $item.VMXName -Path $Destiantion_VM_Workstation -config $item.Config
            if ($test.Scenario -eq 1){
                $VMlab += $item.Config
            }
        }
        catch {
            
        }

    }
    #Start VM Lab
    $VMlab | ForEach-Object {& $global:vmware $_}

    }
}

function New-StormShieldOVAVmware {
    for ($i = 0; $i -le 1; $i++) {
    
        foreach ($item in $Trainee ) {
            
                    $VMname = $item
                    
                    switch ($item)
                    {
                        'Debian-Training-WebMail' 
                        {
                            $disk ="Appareil virtuel (appliance)-disk002.vmdk"
                            $GuestOs = 'debian10' 
                        }
                        'SNS_EVA1_V4'             
                        {
                            $disk ="Appareil virtuel (appliance)-disk001.vmdk"
                            $GuestOs = 'freeBSD-64'
                        }
                    }
                    New-VMX -VMXName $VMname -GuestOS $GuestOs -Firmware BIOS -Path $Destiantion_VM_Workstation |Out-Null
                    Set-VMXDisplayName -DisplayName $VMname -config  "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" |Out-Null
                    Copy-Item -Path "$Source_VM_Disk_VirtualBox\$item\$disk" -Destination "$Destiantion_VM_Workstation\$VMname\$VMname.vmdk" |Out-Null
                    Add-VMXScsiDisk -Diskname "$Destiantion_VM_Workstation\$VMname\$VMname.vmdk"`
                    -VMXName $VMname -config   "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" -LUN 1 -Controller 0 |Out-Null
    
                    $VMs = get-VMX -VMXName $VMname -Path $Destiantion_VM_Workstation
                    switch ($VMs.VMXName)
                    {
                        {'Debian-Training-WebMail'}
                        {   
                            Set-VMXSize -VMXName $VMname -Path  $Destiantion_VM_Workstation -config   "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" -Size XS | Out-Null
                            Set-VMXNetworkAdapter -VMXName $VMname -config "$Destiantion_VM_Workstation\$VMname\$VMname.vmx"  -AdapterType vmxnet3 -Adapter 0 -ConnectionType bridged |Out-Null
                            
                            if(!(Test-Path -Path "$Destiantion_VM_Workstation\$VMname\$VMname.ova"))
                            {   
                                & $VMware_OVFTool "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" "$Destination_OVA_VMware\$VMname.ova"
                            }
                        }
                        {'SNS_EVA1_V4'}           
                        { 
                            Set-VMXSize -VMXName $VMname -Path  $Destiantion_VM_Workstation -config   "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" -Size M | Out-Null
                            for ($i = 0; $i -lt 4; $i++) {
                                Set-VMXNetworkAdapter -VMXName $VMname -config "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" -AdapterType vmxnet3 -Adapter $i -ConnectionType bridged |Out-Null
                            }
                            if(!(Test-Path -Path "$Destiantion_VM_Workstation\$VMname\$VMname.ova"))
                            {   
                                & $VMware_OVFTool "$Destiantion_VM_Workstation\$VMname\$VMname.vmx" "$Destination_OVA_VMware\$VMname.ova"
                            }
                        }
                    }
        }              
    }    
}
function Start-StormShieldLab {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        $Path,
        [Parameter (Mandatory = $true)]
        $ScenarioName

    )
    
    begin 
    {
        $VMs = get-VMX -Path $Path
        $VMlab=@()
    }
    
    process 
    {
        foreach ($item in $VMs) 
        {

            $TestScenario = Get-VMXscenario -VMXName $item.VMXName -Path $Path -config $item.Config
            if ($TestScenario.Scenario -eq 1){
                $VMlab += $item.Config
            }
        }
        foreach ($item in $VMlab) {
            get-VMX -VMXName "$item" -Path $path | Start-VMX 
        }
    }
    
    end {
    }
}
function Export-StormShieldLabStudentsToOVA {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        $Path,
        [Parameter (Mandatory = $true)]
        $ScenarioName,
        [Parameter(Mandatory = $true)]
        $ExportPath

    )
    
    begin {

        $VMs = get-VMX -Path $Path
        $VMlab=@() 
    }
    
    process 
    {
        foreach ($item in $VMs) 
        {

            $TestScenario = Get-VMXscenario -VMXName $item.VMXName -Path $Path -config $item.Config
            if ($TestScenario.Scenario -eq 1){
                $VMlab += $item
            }
        }

        foreach ($item in $VMlab) {

            $AllName = $($item.VMXname).Split("\")
            $FinalName = $AllName[$AllName.count -1]
            $source = $item.Config
            & $VMware_OVFTool "$source" "$ExportPath\$FinalName.ova"
        }


    }
    
}

#Création d'un Lab avec deux Sites A et B et deux Firewall SNS
New-StormShieldLabStudents

#Démarrage du Lab Student
Start-StormShieldLab -Path $Destiantion_VM_Workstation -ScenarioName $ScenarioName

#Exportation du Lab Student vers OVA pour distribution.
Export-StormShieldLabStudentsToOVA -Path $Destiantion_VM_Workstation -ScenarioName $ScenarioName -ExportPath $ExportPath

#Création des OVA pour VMware vSphère 
New-StormShieldOVAVmware


