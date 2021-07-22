#snapshot hunter function
function Snapshot-hunter{
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
# variables
$PathReport="C:\temp\snapshot_hunter"
$Report="C:\temp\snapshot_hunter\$(Get-Date -Format ddMMyyyy)snapshot_report.txt"
$String="*" * 16

#check and create report folder
Write-host "Checking if report folder is present...loading" -ForegroundColor Cyan -BackgroundColor Black
Start-Sleep -Seconds 3
if (Test-Path -Path $PathReport) {
Write-Host "Snapshot Report folder present" -ForegroundColor Green
}
else {
New-Item -Path $PathReport -ItemType Directory | Out-Null
write-host "Report Folder Created - $PathReport" -ForegroundColor Red -BackgroundColor Yellow
Start-Sleep -Seconds 3
}

#check if a a report already exists. It asks you to delete or archive it.The script creates a new one
Write-host "Checking if existing snapshot report is present...loading" -ForegroundColor Cyan -BackgroundColor Black
Start-Sleep -Seconds 3

if (Test-Path -Path $Report) {
Write-Host "!!Snapshot Report already present" -ForegroundColor Red -BackgroundColor Yellow
Invoke-Item $PathReport
Write-Host "Please delete or archive - $Report" -ForegroundColor Red -BackgroundColor Yellow
pause
New-Item -ItemType File -Path $PathReport -Name "$(Get-Date -Format ddMMyyyy)snapshot_report.txt" | Out-Null
write-host "Report Created - $Report" -ForegroundColor Red -BackgroundColor Yellow
Write-Output  $String | Out-File -FilePath $Report
Write-Output "Snapshot Report" | Out-File -FilePath $Report -Append
Write-Output  $String | Out-File -FilePath $Report -Append
}
else {
New-Item -ItemType File -Path $PathReport -Name "$(Get-Date -Format ddMMyyyy)snapshot_report.txt" | Out-Null
write-host "Report Created - $Report" -ForegroundColor Green
Write-Output  $String | Out-File -FilePath $Report
Write-Output "Snapshot Report" | Out-File -FilePath $Report -Append
Write-Output  $String | Out-File -FilePath $Report -Append
}

#Investigates the datastores specified by the users by looking for VM snapshots and opens the report
Write-host "Select datastore you want to inspect...loading" -ForegroundColor Cyan -BackgroundColor Black
Start-Sleep -Seconds 3
$targetDS=Get-Datastore | Out-GridView -PassThru
Write-Output  $targetDS | Out-File -FilePath $Report -Append
get-datastore -Name $targetDS | Get-VM | Get-Snapshot | select-object -Property VM,Name,Created,Description,IsCurrent,@{ n="SizeGB"; e={[math]::round( $_.SizeGB, 3 )}} | Out-File -FilePath $Report -Append
Invoke-item $Report
Disconnect-VIServer -Server $vcenter -Confirm:$false
Write-Host "Thanks for using Snapshot Hunter! Bye" -ForegroundColor Red -BackgroundColor White
pause
}
#end of the function

#start of the script
Write-host "Welcome in Snapshot Hunter - Identify & report VM snapshot" -ForegroundColor DarkGreen -BackgroundColor White
pause

#loop for confirming input before launching loaded function
DO
{$vcenter=Read-host "Please type the FQDN of the vCenter you want to connect to"
$confirmation=Read-host "Please confirm that you want to connect to $vcenter y/n"
}
until ($confirmation -eq "y")
#launch of the function
Snapshot-hunter

<#
.SYNOPSIS
---------
This tool is designed to identify quickly the presence of snapshots on a datastore running low of free space.

.DESCRIPTION
------------
This script has been written with the objective of quickly investigate space issue on datastores.
It eleminates or confirms the presence of snapshots on the concerned datastore. Mostly in big environments, forgotten snapshots are often the root cause of room issue on DS.

The user of the script will receive a report in text format of the supicious datastore with the following information if presence of snapshots is confirmed:
*VM impacted
*Creation date of the snapshot
*Description of the snapshot if it has been specified when created
*if the identified snapshot is the most recent of chain
*the size of the snapshot

This script is designed as follow
Part 1. A function is created to launch the report about the specific datastores you want to analyze
Part 2. A loop that permits to manage user inputs errors when the vcenter name is not the one expected one. Ex: User is aware of a typo error
Part 3. A call of the function is realized to create the report 
This script has no impact on vSphere environment as it retreives data only ( no modification on the infrastructure)

.INPUTS
-------
1. Vcenter you want to connect to
2. Your VC account credentials if they are not stored locally
3. Datastore name you want to inspect. input is done via Outgrid-view function which prevents typo issues (multiple DS can be selected)

.OUTPUTS
--------
The output of the script is the creation of a text file in the following location "C:\temp\snapshot_hunter". 
The script will create the folder to store the report if it doesn't exist
The name of the file is: $(Get-Date -Format ddMMyyyy)snapshot_report.txt -> Currentdatesnapshot_report.txt
For each snapshot found, the report will add the following information:
VM Name (concerned VM)
Creation date of the snapshot
Description (if completed)
Verification if the found snapshot is the current one or if is member of a chain
Size of the Snapshot expressed in GB and rounded to MB
Name of datastore(s) analyzed

.NOTES
------
*VERSION
Current version is v1.1 (22/07/2021)
reviewed the code to get a better workflow of the script

*PREREQUISITE
PowerCLI module 6.5 minimum present on your machine where you run the tool

*LIMITATION
The machine where will be run the script must be a Windows machine as a report will be created in the following folder:
"C:\temp\snapshot_hunter"

*AUTHOR
Michaël Militoni
#>