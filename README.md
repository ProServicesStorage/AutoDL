# AutoDL

For CVAutoDL.ps1

PowerShell that automates creation of Commvault Disk Library mount paths and associated Commvault Disk Library. It's primary purpose is to reduce the tedious work required when presented with a large number of disks to format and mount for a Commvault Disk Library. It's for Windows NTFS based Disk Libraries

Initializes / Onlines / Formats and creates mount point directories in Commvault. 

Also creates Disk Library with Automated Mount Path Detection or adds Automated Mount Path Detection to existing Disk Library.

To create a new disk library with automated mount path detetction run as follows. See example.

        CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts

To add a new automated mount path folder to an existing library add the -add switch. See example.
   
        CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts -add

If there are multiple MediaAgents that need to have share access to the library then add the following additional parameters: -ma2s MediaAgent1,MediaAgent2 -user UserA -psswd MyPassword. See example.
    
        CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts -ma2s MediaAgent2,MediaAgent3 -user UserA -psswd MyPassword

 If just want to get disk ready and not run any Commvault commands. See example.
 
        CVAutoDL.ps1 -disks 4, 5 -dir c:\MyDL\MyDirContainingMounts -d

Enter y or Y at prompt to run script. Anything else exits.

To get help use Get-Help

        Get-Help .\CVAutoDL.ps1

There is also a workflow with the same functionality but can be run remotely.
