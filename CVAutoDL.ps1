
<#

.SYNOPSIS
Automates Disk Library creation for Commvault. 

.DESCRIPTION
Can initialize, bring online, format, and create mount point directories for Commvault. Also, can automatically create Commvault Automated Mount Path Detection

.EXAMPLE
CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts
CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts -add
CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts -ma2s MediaAgent2,MediaAgent3 -user UserA -psswd MyPassword
CVAutoDL.ps1 -disks 4, 5 -dir c:\MyDL\MyDirContainingMounts -d

.NOTES
--Initializes / Onlines / Formats and creates mount point directories for Commvault. 
--Also creates Disk Library with Automated Mount Path Detection or adds Automated Mount Path Detection to existing Disk Library.
 To create a new disk library with automated mount path detetction run as follows. ex. CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts
 To add a new automated mount path folder to an existing library add the -add switch
		ex. CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts -add
 If there are multiple MediaAgents that need to have share access to the library then add the following additional parameters: -ma2s MediaAgent1,MediaAgent2 -user UserA -psswd MyPassword
		ex.  CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts -ma2s MediaAgent2,MediaAgent3 -user UserA -psswd MyPassword
 If just want to get disk ready and not run any Commvault commands. ex. CVAutoDL.ps1 -disks 4, 5 -dir c:\MyDL\MyDirContainingMounts -d
 Enter y or Y at prompt to run script. Anything else exits.

.LINK
https://proservicesstorage.com/

#>



#Accept user defined input
param ([String[]] $disks, [String] $dir, [String] $lib, [String] $ma,[String[]] $ma2s,[String] $user,[String] $psswd,[switch] $add,[switch] $d )

#For use with sharing mount paths
$myArrayofPrimaryPaths = @()


#Functions go here --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Initialize Disk. Create a new partition
Function Get-DiskReady

	{
		
		$drvtmp1 = ls function:[d-z]: -n | ?{ !(test-path $_) } | select -Last 1
		$drvtmp2 = $drvtmp1 -replace ".$"
		foreach($disk in $disks)
			{
				Set-Disk -Number $disk -IsOffline $false
				Set-Disk -Number $disk -IsReadOnly $false
				#Initialize-Disk -Number $disk -PartitionStyle GPT
				Clear-Disk -Number $disk -RemoveData -Confirm:$false -ErrorAction SilentlyContinue
				Start-sleep 1
				Initialize-Disk -Number $disk -PartitionStyle GPT
				Start-sleep 1
				New-Partition -DiskNumber $disk -UseMaximumSize
				Start-sleep 1
				#It is necessary to add a drive temporarily to format the volume. Format-Volume can be piped into Add-PartitionAccessPath but there appeared to be a timing issue where it was necessary to add a 1 sec sleep.
				Add-PartitionAccessPath -DiskNumber $disk -PartitionNumber 2 -AccessPath $drvtmp1
				Start-sleep 1
				Format-Volume -DriveLetter $drvtmp2 -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false
				Start-sleep 1
				#Partition 2 for GPT and Partition 1 for MBR
				Remove-PartitionAccessPath -DiskNumber $disk -PartitionNumber 2 -AccessPath $drvtmp1
				Start-sleep 1
			}
	} #End function Get-DiskReady



#Create folders and mount disks
Function Create-MountPoint 

	{
	
	#Directory where mount points will be created
	$MountDirectory = $dir

	if(!(Test-Path -Path $MountDirectory )) 
		
		{

			New-Item -ItemType directory -Path $MountDirectory

		}

	foreach ($disk in $disks)

		{
			$MountName = '\Mount'+$disk
			$path = $MountDirectory+$MountName
			$myArrayofPrimaryPaths += $path
			
			if(!(Test-Path -Path $path )) 
			
				{
					New-Item -ItemType directory -Path $path

				}

			Add-PartitionAccessPath -DiskNumber $disk -PartitionNumber 2 -AccessPath $path 

		}
	} #End Function Create-AutoMount


#Share Mount Paths with other MediaAgents
Function ShareAutoMount 

	{
			   
		Write-Host "There is a secondary MA!"
		#Wait for 5 minutes after service restart to let the automated mount paths get created otherwise nothing to share!
		sleep 300

		foreach ($ma2 in $ma2s)

			{

				foreach ($path2 in $myArrayofPrimaryPaths)
					{


						$path3 = $path2 -replace "\:\\","$\"
						$path4 = "\\"+$ma+"\"+$path3
						$ma2
						$path4

						$tmp2 = [System.IO.Path]::GetTempFileName()

						$TmpXML = '<EVGui_ConfigureStorageLibraryReq>
						<library libraryName="'+$lib+'" mediaAgentName="'+$ma+'" mountPath="'+$path2+'" opType="64"/>
						<libNewProp deviceAccessType="4" mountPath="'+$path4+'" mediaAgentName="'+$ma2+'" loginName="'+$user+'" password="'+$psswd+'" proxyPassword=""/>
						</EVGui_ConfigureStorageLibraryReq>'

						$TmpXML | Set-Content $tmp2

						qoperation execute -af $tmp2
						Remove-Item $tmp2

					}

			}
	} #End Function ShareAutoMount


# Add Automated Mount Path Detection folder to existing library. 
Function AddAutoMount 

	{
	

		$tmp2 = [System.IO.Path]::GetTempFileName()

		$TmpXML ='<EVGui_ConfigureStorageLibraryReq isConfigRequired="1"> 
		<library baseFolder="CVDiskFolder" libraryName="'+$lib+'" mediaAgentName="'+$ma+'" mountPath="'+$dir+'" opType="4"/> 
		</EVGui_ConfigureStorageLibraryReq>'
		$TmpXML | Set-Content $tmp2

		qoperation execute -af $tmp2
		#Legacy reguired xml file. qoperation execute -af add_mount_point.xml -library/libraryName "$lib" -mediaAgentName "$ma" -mountPath "$dir"
		start-sleep 5
		restart-service 'GXMMM(Instance001)'
		
		if($ma2s)
			{
				ShareAutoMount
		else 
				Write-Host "There is no secondary MA to share with!"        
			}
	
	} #End function AddAutoMount



Function CreateAutoMount
	{
		$tmp2 = [System.IO.Path]::GetTempFileName()
		$TmpXML = '<EVGui_ConfigureStorageLibraryReq isConfigRequired="1">
			<library baseFolder="CVDiskFolder" libraryName="'+$lib+'" mediaAgentId="" mediaAgentName="'+$ma+'" mountPath="'+$dir+'" opType="1"/>
		</EVGui_ConfigureStorageLibraryReq>'
		$TmpXML | Set-Content $tmp2

		qoperation execute -af $tmp2

		#qoperation execute -af create_mount_point.xml -library/libraryName "$lib" -mediaAgentName "$ma" -mountPath "$dir"
		start-sleep 5
		restart-service 'GXMMM(Instance001)'
		
			if($ma2s)
				{
					ShareAutoMount
			else 
					Write-Host "There is no secondary MA to share with!"        
				}
	} #End function CreateAutoMount

#End Functions-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





#Main Code goes here-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$confirmation = Read-Host "Are you Sure You Want To Proceed? All disks specified will be destroyed!:"
if ($confirmation -eq 'y') 
	# proceed
	{
		
		If ($d)
			{
				Get-DiskReady
				Create-MountPoint
				Write-Host "Just handling the disks!"
				Write-Host "This script is complete!!!"  
				exit 01
			}
				
		Get-DiskReady
		Create-MountPoint

		Write-Host "Time to do Commvault stuff!"  

		if ($add)
			
			{
				Write-Host "-add option selected"  
				AddAutoMount
				Write-Host "This script is complete!!!"  
				exit 01
			}
			
		CreateAutoMount
		Write-Host "This script is complete!!!"  

	}

#End Main Code-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



#--Last Edited by Mark Richardson on 5/21/2019
	#Removes Requirement for any xml files as will be temporarily generated by the script
	#Cleaned up comments
	#Improved documenation
	#Created repository in github
	#Modified code to use functions
	#Added -d option to just handle disks and not run any Commvault commands
	#Added confirmation prompt
	#Added help. Uses Get-Help 
