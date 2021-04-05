<#
.SYNOPSIS
---------

This script permits the VM Admin to use the Cross vCenter vMotion functionnality introduced in vSphere 6.x which permits the live move of VM across different vCenters
via Powershell/PowerCLI


.DESCRIPTION
------------

This script was written first in the context of Moving VM across vCenters that are part of different SSO domains to address Web GUI limitation
Web GUI connect to multiple vCenters which reside in different SSO domains. Only vCenters in same SSO (Enhanced Linked Mode) is functional.

VMware team build a Fling that do the same thing (even in a better way), but as this tool is experimental (as all others flings), it should not be used in Production environment
Please refer to this link to get a better view on this VMware fling and limitations (https://flings.vmware.com/cross-vcenter-workload-migration-utility#requirements).
This script is supportable as it uses only PowerShell/PowerCLI to reach the objective of moving a VM from vCenter A to vCenter B.

This script is fully interactive which means that the VM admin will need to pass required information while the script is running to accomplish the Cross vCenter VM migration.
This prevents the VM admin to change the code before each use (typically changing variables) and stores in the script sensitive passwords.

The script will permit you to move 2 typical types of workload. Simple VM (one NIC - One VMDK) and Advanced VM (Multiple NIC - Multiple VMDK)

Consider to use Advanced VM type in the following cases:
--------------------------------------------------------
1 NIC - MULTIPLE VMDK
MULTIPLE NICS - 1 VMDK
MUTLIPLE NICS - MUTIPLE VMDK

The actions will be initiated by the operator via the menu actions:

Action 1: Will throw a POP-UP to VM Admin with System requirements summary for initating a VM Migration in good conditions
          Will launch the VMware KB page with the default browser of the VM admin to review in details the system requirements

Action 2: Will throw a POP-UP to VM Admin with the information he needs for running the VM Migration
          Typically the information he will need when script will request his input (script variables)

Action 3: Will create a new folder on VM admin workstation to store the requested information about VM to migrate
          Will ask to define the vCenter FQDN where resides the VM
          Will connect to the provided vCenter
          Will ask to define the name of the VM to migrate
          Will check the VMDK related to the VM and stores information in a new text file located in the new folder created
          Will check the VMNIC related to the VM and stores information in the same text file located in the new folder created
          Will open the file for VM Admin

Action 4: Will process the migration of the VM based on the VM Admin input
          Will Configure the PowerShell/CLI session to connect to multiple vCenters
          Will ask to define the Source Vcenter where the VM resides and connect to it
          Will ask to define the Destination Vcenter where the VM will be moved to and connect to it
          Will ask to define the name of the VM to migrate
          Will ask to define the name of the ESXI where the VM will be migrated to
          Will ask to define the name of the Destination dVswitch in the Destination vCenter
          Will ask to define the name of the Destination dVswitch in the Destination vCenter
          Will ask to define the name of the Destination PortGroup in the Destination dVSwitch
          Will pass the VMNIC of the VM to migrate in variable
          Will ask to define the name of the Destination datastore connected to the destination ESXi
          Will process the migration of the VM based on the input of the VM admin
          Will disconnect from both vCenters


Action 5: Will process the migration of the VM based on the VM Admin input
          Will Configure the PowerShell/CLI session to connect to multiple vCenters
          Will ask to define the Source Vcenter where the VM resides and connect to it
          Will ask to define the Destination Vcenter where the VM will be moved to and connect to it
          Will ask to define the name of the VM to migrate
          Will ask to define the name of the ESXI Cluster where the VM will be migrated to
          Will pass the ESXI cluster name in a variable to get the name of the destination ESXI (workaround due to cmdlet limitation)
          Will ask to define the name of the Destination dVswitch in the Destination vCenter
          Will ask to define the name of the Destination PortGroups in the Destination dVSwitch (multiple  - comma seperated without whitespace)
          Will pass the VMNIC of the VM to migrate in variable
          Will ask to define the name of the Destination datastore cluster connected to the destination ESXi Cluster
          Will pass the Datastore cluster name in a variable to get the name of the destination datastore (workaround due to cmdlet limitation)
          Will process the migration of the VM based on the input of the VM admin
          Will disconnect from both vCenters

Action Q: to quit - Will close the script after confirmation
            
.NOTES
-------

*VERSION

 1.0

*PREREQUESITE

PowerCLI 6.5 module is the minimum version you need to run the script as the cmdlet MOVE-VM was introduced in this version of PowerCLI
Others prerequisites (infrastructure side) are mentionned in the action menu '1' of the script and here: https://kb.vmware.com/s/article/2106952  


*LIMITATION

In the initial version of the script you can move VM one by one. In the future version, you will be able to run xvCenter vMotion for a batch of VMs


*AUTHOR
-------
Michaël Militoni
#>

Write-Host "Welcome in the xVcenter VM Migration tool v1.0 VM Admin!" -ForegroundColor Cyan
pause
do {
Write-Host "============================ Pick Your VM Migration Task================================" -ForegroundColor Magenta
Write-Host "Execute tasks from 1 to 3 for Pre-checks before migration" -ForegroundColor Cyan
Write-Host "Execute tasks 4 or 5 To migrate VM depending of its type" -ForegroundColor Cyan
Write-Host "1: Press '1' Check requirements before VM Migration (info only - no checks)" -ForegroundColor Green
Write-Host "2: Press '2' Gather the info you need to run the script smoothly (info only - no checks)" -ForegroundColor Green
Write-Host "3: Press '3' Check VM Hard disks and NICS to determine your next action (4 or 5)" -ForegroundColor Green
Write-Host "4: Press '4' Migrate VM -Single Disk - Single NIC. (Simple VM)" -ForegroundColor Yellow
Write-Host "5: Press '5' Migrate VM -Multiple Disks - Multiple NICs.(Advanced VM - DSCluster env)" -ForegroundColor Yellow
Write-Host "Q: Press 'Q' to quit." -ForegroundColor Green
Write-Host "========================================================================================" -ForegroundColor Magenta
$choice = Read-Host "Please choose your next action"
switch ($choice)
{
   '1'{
         Write-Host "You have chosen to review requirements for xVcenter vMotion" -ForegroundColor Cyan
         Start-Process "https://kb.vmware.com/s/article/2106952"
         Add-Type -AssemblyName PresentationFramework
         [System.Windows.MessageBox]::Show('check that TCP ports are open between source and destination vcenters + hosts
         TCP 902 & 8000 between source & destination ESX, TCP 443 between source & destination vCenters
         Check your SSO topology across source and destination vCenters
         VMotion network IP reachable on both source and destination ESXi hosts
         PowerCLI 6.5 as a minimum version for running Move-VM cmdlet included in this script
         For more information check VMware KB https://kb.vmware.com/s/article/2106952','xVcenter VM Migration Requirements','OK','Information')
        
   }

   '2'{
         Write-Host "You have chosen to review the requested information to run the VM migration" -ForegroundColor Cyan
         Add-Type -AssemblyName PresentationFramework
         [System.Windows.MessageBox]::Show('1. Source vCenter FQDN + credentials
         2. Destination vCenter FQDN + credentials
         3. VM name on Source vCenter
         4. Name of destination ESXi host / Cluster where the VM will be migrated to
         5. Name of the destination Datastore (single VMDK)
         6. Name of the destination Datastore cluster (Multiple VMDK)
         7. Name of the destination PortGroup and DvSwitch','xVcenter VM Migration preparation','OK','Information')
         
              
   }
   '3'{
        Write-Host "You have chosen to check VMDK and NICS of VM to Migrate" -ForegroundColor Cyan
        if (!(Test-Path "C:\Temp\xVcenterMoveVM")){ 
        New-Item -path "C:\Temp\xVcenterMoveVM" -type directory -Force -ErrorAction SilentlyContinue |Out-Null}
        $SourceVC=Read-Host "Enter Source vCenter FQDN name where VM resides"
        Connect-VIServer $SourceVC
        $SourceVM=Read-Host "Enter Source VM name to check"
        Get-VM $SourceVM | Get-HardDisk | Format-Table -AutoSize | Out-File -FilePath "C:\Temp\xVcenterMoveVM\$SourceVM.txt"
        Get-VM $SourceVM | Get-NetworkAdapter | Format-Table -AutoSize | Out-File -FilePath "C:\Temp\xVcenterMoveVM\$SourceVM.txt" -Append
        Start-Process "C:\Temp\xVcenterMoveVM\$SourceVM.txt"
        Disconnect-VIServer $SourceVC -Confirm:$false
              
   }
   '4'{
       Write-Host "You have chosen to Migrate VM -Single VMDK -Single NIC" -ForegroundColor Cyan
       Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false | Out-Null
       $SourceVC=Read-Host "Enter Source vCenter FQDN name where VM resides"
       Connect-VIServer $SourceVC
       $DestinationVC=Read-Host "Enter Destination vCenter FQDN name where VM will be migrated to"
       Connect-VIServer $DestinationVC
       $SourceVM=Read-Host "Enter Source VM name to Migrate"
       $DestinationESXi=Read-Host "Enter Destination ESXi FQDN Name"
       $DestinationDVSwitch=Read-Host "Enter Destination DvSwitch Name"
       $DestPortGroup=Read-Host "Enter Destination PortGroup Name"
       $destinationPortGroup=Get-VDPortgroup -VDSwitch $DestinationDVSwitch -Name $DestPortGroup
       $VMNICadapter= Get-NetworkAdapter -VM $SourceVM
       $DestinationDatastore=Read-Host "Enter unique Destination Datastore Name"
       Move-VM $SourceVM -Destination $DestinationESXi -NetworkAdapter $VMNICadapter -PortGroup $destinationPortGroup -Datastore $DestinationDatastore -VMotionPriority High -Server $DefaultVIServers -Confirm
       Disconnect-VIServer $SourceVC -Confirm:$false
       Disconnect-VIServer $DestinationVC -Confirm:$false
             
   }
   '5'{
       Write-Host "You have chosen to Migrate VM -Mutiple VMDK -Multiple NIC" -ForegroundColor Cyan
       Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false | Out-Null
       $SourceVC=Read-Host "Enter Source vCenter FQDN name where VM resides"
       Connect-VIServer $SourceVC
       $DestinationVC=Read-Host "Enter Destination vCenter FQDN name where VM will be migrated to"
       Connect-VIServer $DestinationVC
       $SourceVM=Read-Host "Enter Source VM name to Migrate"
       $DestinationCluster=Read-Host "Enter Destination ESXi Cluster Name"
       $DestinationESXi=Get-Cluster -name $DestinationCluster | Get-VMhost | select-Object -First 1
       $DestinationDVSwitch=Read-Host "Enter Destination DvSwitch Name"
       $DestPortGroup=Read-Host "Enter Destination PortGroup Names - Split them with comma"
       $DestPortGroups=$DestPortGroup.Split(",")
       $destinationPortGroup=Get-VDPortgroup -VDSwitch $DestinationDVSwitch -Name $DestPortGroups
       $VMNICadapter= Get-NetworkAdapter -VM $SourceVM
       $DestinationDatastorecls=Read-Host "Enter Destination Datastore Cluster Name"
       $DestinationDatastore=Get-DatastoreCluster -Name $DestinationDatastorecls -Server $DestinationVC | Get-Datastore
       Move-VM $SourceVM -Destination $DestinationESXi -NetworkAdapter $VMNICadapter -PortGroup $destinationPortGroup -Datastore $DestinationDatastore -VMotionPriority High -Server $DefaultVIServers -Confirm
       Disconnect-VIServer $SourceVC -Confirm:$false
       Disconnect-VIServer $DestinationVC -Confirm:$false
               
   }
   'Q'{
         Write-Host "You have chosen to quit the xVcenter VM Migration tool! Bye VM Admin" -ForegroundColor DarkRed -BackgroundColor White
         pause
   }
   }}
   until ($choice -eq 'Q')