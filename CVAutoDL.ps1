# Commvault Professional Services 2018
	# !!!CAUTION!!! - Data destructive so understand what you are doing first!
    # Ex: c:\scripts\cvautodl.ps1 -disks 4, 6, 8, 9, 10 -dir c:\commvault\disklibrary\ -init
    # If omit -init then non-destructive and will only create directory moun folders
 


#Create Windows OS Mounts for Disk Library.
    


param ([String[]] $disks, [String] $dir, [String] $lib, [String] $ma,[String[]] $ma2s,[String] $user,[String] $psswd,[switch] $add)

$MountDirectory = $dir

$drvtmp1 = ls function:[d-z]: -n | ?{ !(test-path $_) } | select -Last 1
$drvtmp2 = $drvtmp1 -replace ".$"

$myArrayofPrimaryPaths = @()


if(!(Test-Path -Path $MountDirectory )) 
    
{

    New-Item -ItemType directory -Path $MountDirectory

}




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




foreach ($disk in $disks)

{
	$MountName = '\Mount'+$disk
	$path = $MountDirectory+$MountName
    	$myArrayofPrimaryPaths += $path
	#$path

    if(!(Test-Path -Path $path )) 
    
    {
        New-Item -ItemType directory -Path $path

    }

	#start-sleep 1
	Add-PartitionAccessPath -DiskNumber $disk -PartitionNumber 2 -AccessPath $path 


}


# Create Disk Library with Automated Mount Path Detection and share out to other MediaAgents

#Create Disk Lib with AutoMount or add another AutoMount Folder to existing Disk Lib

if ($add)
{
$temptxt = "woo hoo"
$temptxt

qoperation execute -af add_mount_point.xml -library/libraryName "$lib" -mediaAgentName "$ma" -mountPath "$dir"
start-sleep 5
restart-service 'GXMMM(Instance001)'
sleep 300

#Share Mount Paths with other MediaAgents

    # Input Code here
    # Maybe Sleep 20 minutes (15 default scan + 5 to complete process)

#qoperation execute -af share_mount_path_example.xml

foreach ($ma2 in $ma2s)
{
#$ma2
foreach ($path2 in $myArrayofPrimaryPaths)
{

#$path2
$path3 = $path2 -replace "\:\\","$\"
$path4 = "\\"+$ma+"\"+$path3
$ma2
$path4

$tmp2 = [System.IO.Path]::GetTempFileName()
#$tmp3 = $tmp2+".xml"
$TmpXML = '<EVGui_ConfigureStorageLibraryReq>
<library libraryName="'+$lib+'" mediaAgentName="'+$ma+'" mountPath="'+$path2+'" opType="64"/>
<libNewProp deviceAccessType="4" mountPath="'+$path4+'" mediaAgentName="'+$ma2+'" loginName="'+$user+'" password="'+$psswd+'" proxyPassword=""/>
</EVGui_ConfigureStorageLibraryReq>'
#$Mount1
$TmpXML | Set-Content $tmp2

#cat $tmp2
#Remove-Item $tmp2
#Clear-Variable $tmp2

qoperation execute -af $tmp2
Remove-Item $tmp2

}

}

}
else
{



qoperation execute -af create_mount_point.xml -library/libraryName "$lib" -mediaAgentName "$ma" -mountPath "$dir"
start-sleep 5
restart-service 'GXMMM(Instance001)'
sleep 300

#Share Mount Paths with other MediaAgents

    # Input Code here
    # Maybe Sleep 20 minutes (15 default scan + 5 to complete process)

#qoperation execute -af share_mount_path_example.xml

foreach ($ma2 in $ma2s)
{
#$ma2
foreach ($path2 in $myArrayofPrimaryPaths)
{

#$path2
$path3 = $path2 -replace "\:\\","$\"
$path4 = "\\"+$ma+"\"+$path3
$ma2
$path4

$tmp2 = [System.IO.Path]::GetTempFileName()
#$tmp3 = $tmp2+".xml"
$TmpXML = '<EVGui_ConfigureStorageLibraryReq>
<library libraryName="'+$lib+'" mediaAgentName="'+$ma+'" mountPath="'+$path2+'" opType="64"/>
<libNewProp deviceAccessType="4" mountPath="'+$path4+'" mediaAgentName="'+$ma2+'" loginName="'+$user+'" password="'+$psswd+'" proxyPassword=""/>
</EVGui_ConfigureStorageLibraryReq>'
#$Mount1
$TmpXML | Set-Content $tmp2

#cat $tmp2
#Remove-Item $tmp2
#Clear-Variable $tmp2

qoperation execute -af $tmp2
Remove-Item $tmp2

}

}

}


