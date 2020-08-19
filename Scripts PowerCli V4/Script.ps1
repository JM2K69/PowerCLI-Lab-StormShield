# Changer les valeurs en fonction de votre environnement.
$Source_VM_Disk_VirtualBox = 'D:\2020 Storm\VirtualBox VMs\OVA_virtual_lab'
$Destiantion_VM_Workstation = 'D:\Virtual Machines'
$ExportPath = 'D:\Virtual Machines'
$Destination_OVA_VMware = 'D:\Virtual Machines'
Import-Module '.\vmxtoolkit\4.5.3.1\vmxtoolkit.psm1'
$ScenarioName = "StormLab"
& (".\init.ps1")

################## Functions ###################

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

    $Trainee = ("Debian-Training-WebMail", "SNS_EVA1_V4")

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
                            
                            if(!(Test-Path -Path "$Destination_OVA_VMware\$VMname.ova"))
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
                            if(!(Test-Path -Path "$Destination_OVA_VMware\$VMname.ova"))
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
                $VMlab += $item.VMXName
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

################## End Functions ###################


#Création d'un Lab avec deux Sites A et B et deux Firewall SNS
New-StormShieldLabStudents

#Démarrage du Lab Student
Start-StormShieldLab -Path $Destiantion_VM_Workstation -ScenarioName $ScenarioName

#Exportation du Lab Student vers OVA pour distribution.
Export-StormShieldLabStudentsToOVA -Path $Destiantion_VM_Workstation -ScenarioName $ScenarioName -ExportPath $ExportPath

#Création des OVA pour VMware vSphère 
New-StormShieldOVAVmware


