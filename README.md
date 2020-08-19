# PowerCLI-Lab-StormShield

Cet outil permet de déployer des laboratoires StormShield dans VMware vSphère 6.x **actuellement** il ne supporte pas la dernière version des `Machines virtuelles` **v4** livrées par StormShield.

# Script compatibles v4

Le script **PowerShell** contenu dans le dossier `Scripts V4` contient un module powershell `vmxtoolkit` que j'ai modifié pour permettre  certaines opérations.
Ce module **PowerShell** permet de piloter `VMware WorkStation`.

Voici les opérations offertes par le script **Script.ps1**

1.  La **création d'un Laboratoire** avec deux sites **A** et **B** et deux Firewalls SNS
1. **L'exportation** d'un Lab Student en OVA pour distribuer le laboratoire aux étudiants du BTS SIO
1. La **création** de VM pour l'exportation au format OVA pour **VMware vSphère** à partir de VMware vSphère 6.x

## Comment utiliser le script

>Au **préalable** vous devez avoir extrait l'OVA forunit par **StormShield** avec **VirtualBox** VMware Workstation doit être Installeé.
- Assurez-vous que la securité d'exécution des scripts et bien configuré
```powershell
PS c:\Get-ExecutionPolicy
RemoteSigned
``` 
Sinon
```powershell
PS c:\Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
- Définissez les variables 
```powershell
# Changer les valeurs en fonction de votre environnement.
$Source_VM_Disk_VirtualBox = 'D:\2020 Storm\VirtualBox VMs\OVA_virtual_lab'
$Destiantion_VM_Workstation = 'D:\Virtual Machines'
$ExportPath = 'D:\Virtual Machines'
$Destination_OVA_VMware = 'D:\Virtual Machines'
Import-Module '.\vmxtoolkit\4.5.3.1\vmxtoolkit.psm1'
$ScenarioName = "StormLab" # attention au nombre de caractèresde cette variable
& (".\init.ps1") # script qui permet d'initialiser certaines varaibles et fonction du module
```
- Executer ces lignes ci-dessus selectionner les et sous **Visual Code** cliquer sur **F8**
- Charger les fonctions **PowerShell** en les selectionnant puis  cliquer sur **F8**

- **Exécuter** la fonction de votre choix
```powershell
#Création d'un Lab avec deux Sites A et B et deux Firewall SNS
New-StormShieldLabStudents

#Démarrage du Lab Student
Start-StormShieldLab -Path $Destiantion_VM_Workstation -ScenarioName $ScenarioName

#Exportation du Lab Student vers OVA pour distribution.
Export-StormShieldLabStudentsToOVA -Path $Destiantion_VM_Workstation -ScenarioName $ScenarioName -ExportPath $ExportPath

#Création des OVA pour VMware vSphère 
New-StormShieldOVAVMware

```
