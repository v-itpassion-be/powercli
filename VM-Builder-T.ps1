Write-Host "Welcome in VM Builder from Template" -ForegroundColor DarkGreen -BackgroundColor White
Start-Sleep -Seconds 5
DO
{$vcenter=Read-host "Please type the FQDN of the vCenter you want to connect to"
$confirmation=Read-host "Please confirm that you want to connect to $vcenter y/n"
}
until ($confirmation -eq "y")

Try{
Connect-VIServer $vcenter -ErrorAction Stop
}
catch {
$ErrorMessage = $_.Exception.Message
Write-Host "Alert!!!! Connection to vCenter failed: $ErrorMessage" -ForegroundColor Red -BackgroundColor Yellow
pause
Write-Host "Please Restart the script" -ForegroundColor Red
start-sleep -Seconds 5
break
}
DO{
Write-Host "Let build your vm on $vcenter" -ForegroundColor DarkGreen -BackgroundColor White
$vmname=Read-Host "Please type the VM Name you want for the new VM"
start-sleep -Seconds 3

Write-host "Please select the Template you want to build the VM from" -ForegroundColor Cyan
start-sleep -Seconds 3
$vmtemplate=Get-Template | Out-GridView -Title "Source Template" -PassThru

Write-host "Please select the vCenter folder you want to place the VM" -ForegroundColor Cyan
start-sleep -Seconds 3
$vmfolder=Get-Folder | Out-GridView -Title "Target Folder" -PassThru

Write-host "Please select the Datastore you want for the VM" -ForegroundColor Cyan
start-sleep -Seconds 3
$vmdatastore=Get-Datastore | Out-GridView -Title "Target Datastore" -PassThru

Write-host "Please select the ESX you want to place the VM" -ForegroundColor Cyan
start-sleep -Seconds 3
$Esx=Get-VMHost | Out-GridView -Title "Target ESX" -PassThru

Write-host "Please select the vSwitch Protgroup (VLAN)" -ForegroundColor Cyan
start-sleep -Seconds 3
$PG=Get-VirtualPortGroup -VMHost $Esx | Out-GridView -Title "Target PortGroup" -PassThru

Write-host "Please select the Guest OS Customization you want" -ForegroundColor Cyan
start-sleep -Seconds 3
$GuestCustom=Get-OSCustomizationSpec | Out-GridView -Title "Guest OS Customization" -PassThru

Write-host "Recap of your input" -ForegroundColor Red -BackgroundColor Cyan
$vmname.name
$vmtemplate.name
$vmfolder.name
$vmdatastore.name
$Esx.name
$GuestCustom.name

$confirmation=Read-host "Please confirm that your input is correct y/n"
} until ($confirmation -eq "y")

Try{
New-VM -Name $vmname -OSCustomizationSpec $GuestCustom -VMHost $Esx -Location $vmfolder -Datastore $vmdatastore -Template $vmtemplate -Portgroup $PG | Out-Null
}
catch{
$ErrorMessage = $_.Exception.Message
Write-Host "Alert!!!! Failed to create VM: $ErrorMessage" -ForegroundColor Red -BackgroundColor Yellow
pause
Write-Host "Please Restart the script" -ForegroundColor Red
start-sleep -Seconds 5
break
}
Write-Host "You successfully created $vmname" -ForegroundColor DarkGreen -BackgroundColor White
Start-Sleep -Seconds 5

$confirmationv2=Read-host "Do you want to reconfigure RAM & CPU y/n"

if ($confirmationv2 -eq "y")
{
$vcpu=Read-host "Please determine the number of vCPU you want"
$cores=Read-Host "Please determine the number of vCores you want"
$memory=Read-host "Please determine the quantity of memory you want (GB)"
Try{Set-VM $vmname -NumCpu $vcpu -CoresPerSocket $cores -MemoryGB $memory -Confirm:$false | Out-Null
}
Catch{
$ErrorMessage = $_.Exception.Message
Write-Host "Alert!!!! Failed to resize VM: $ErrorMessage" -ForegroundColor Red -BackgroundColor Yellow
pause
}
}

else{
}
try{
start-vm $vmname -Confirm:$true | Out-Null
}
Catch{
$ErrorMessage = $_.Exception.Message
Write-Host "Alert!!!! Failed to start VM: $ErrorMessage" -ForegroundColor Red -BackgroundColor Yellow
pause
}

Get-VM $vmname | Select-Object -Property Name,PowerState
Start-Sleep -Seconds 3

Disconnect-VIServer $vcenter -Confirm:$false

Write-Host "Thanks for using VM Builder from Template - AutoShutdown in progress !" -ForegroundColor DarkGreen -BackgroundColor White
Start-Sleep -Seconds 10
break
<#
.SYNOPSIS
In some environments sysadmins need to deploy VM from templates instead of using classic WDS.
The script has been created to permit Sysadmins to build a new VM from PowerShell instead of vSphere GUI for more efficiency and simplicity.
.DESCRIPTION
The script will build a VM based on the input received by the user of the script.

The workflow is as follow:
**************************
Step 1: Sysadmin connects to a specific vcenter where to build the new VM.
Step 2: Sysadmin will input all the required information to permit the script to build the VM.
Step 3: The script builds the VM and ask the user if he needs additional modifications on the VM (CPU/RAM).
Step 4: The script asks the user if it needs to start the new built VM.
Step 4: The script auto-shutdown

Error handling is managed by to kind of actions:
************************************************

DO... UNTIL (human error)
TRY...CATCH (system & human error)

.INPUTS
As the script is interactive, it requires some input from the user of the script.
The typo errors are suppressed by the Out-gridview command which permits the user to select the data instead of typing it.
Here is the requested input that is mandatory for the script being able to create the VM.

Vcenter FQDN
VMNAME (name of the new VM to build)
VMTEMPLATE (the template that will be used as foundation for the building of the VM)
VMFOLDER
VMDATASTORE ( The datasore VMFS/NFS where will reside the VM)
ESX (The initial ESXi host that will run the VM)
VMINC PG (The port Group associated to VMNIC1 of the VM / Standard of Distributed vSwitch)
GUESTCUSTOMIZATION (Specifies the Guest OS customization template that will be used for launching the sysprep operations)

.OUTPUTS
The script is quite verbose, so the user will receive extensive information
The main output is the following:
Confirmation of the creation of the VM and its' powerstate

.NOTES
    *VERSION
    Version 1.0 @ 19/07/2021

    *PREREQUISITE
    PowerShell 5.x installed and functional
    PowerCLI module for PowerShell
    A VM template
    
    *LIMITATION
    Only 1 VM at a time can be deployed with this script
    
    *AUTHOR
    Michaël Militoni @ NRB
#>