# AutoDL
PowerShell that automates creation of Commvault Disk Libraries

Initializes / Onlines / Formats and creates mount point directories for Commvault. 

Also creates Disk Library with Automated Mount Path Detection or adds Automated Mount Path Detection to existing Disk Library.

To create a new disk library with automated mount path detetction run as follows. ex. CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts

To add a new automated mount path folder to an existing library add the -add switch
    ex. CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts -add

If there are multiple MediaAgents that need to have share access to the library then add the following additional parameters: -ma2s MediaAgent1,MediaAgent2 -user UserA -psswd MyPassword
    ex.  CVAutoDL.ps1 -disks 5,6,7,8,9 -lib MyDiskLibrary -ma cs11 -dir c:\commvault\myDirContainingMounts -ma2s MediaAgent2,MediaAgent3 -user UserA -psswd MyPassword

