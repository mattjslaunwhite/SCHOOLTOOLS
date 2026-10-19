Here is an automated PowerShell script designed to run on Windows 11 with Hyper-V enabled. It creates the LinuxFinal Project VM, allocates 4 GB of RAM, provisions and attaches both the primary 127 GB dynamic OS .vhdx and the secondary 50 GB data .vhdx, configures the DVD drive, and binds to your virtual switch.

Prerequisites Before Running
Open PowerShell by right-clicking and selecting Run as Administrator.

Have your Fedora Workstation .iso file downloaded on your Windows drive (update the $IsoPath variable below).

What to Expect Next Inside the VM
Boot into Live Media: Run Start-VM -Name "LinuxFinal Project" and launch vmconnect localhost "LinuxFinal Project".

Install to 127 GB Disk: In the Anaconda installer, select the 127 GB drive as the installation target with default automatic BTRFS partitioning (leave the 50 GB drive unselected during initial OS install).

First User Creation: Set full name/username to woot.

Once the installer finishes and you reboot into the installed system, /dev/sdb will be waiting completely blank for Step 4 (fdisk /dev/sdb to make the 30 GB ext4 and 20 GB xfs partitions).
