Here is an automated PowerShell script designed to run on Windows 11 with Hyper-V enabled. It creates the LinuxFinal Project VM, allocates 4 GB of RAM, provisions and attaches both the primary 127 GB dynamic OS .vhdx and the secondary 50 GB data .vhdx, configures the DVD drive, and binds to your virtual switch.

Prerequisites Before Running
Open PowerShell by right-clicking and selecting Run as Administrator.

Have your Fedora Workstation .iso file downloaded on your Windows drive (update the $IsoPath variable below).

What to Expect Next Inside the VM
Boot into Live Media: Run Start-VM -Name "LinuxFinal Project" and launch vmconnect localhost "LinuxFinal Project".

Install to 127 GB Disk: In the Anaconda installer, select the 127 GB drive as the installation target with default automatic BTRFS partitioning (leave the 50 GB drive unselected during initial OS install).

First User Creation: Set full name/username to woot.

Once the installer finishes and you reboot into the installed system, /dev/sdb will be waiting completely blank for Step 4 (fdisk /dev/sdb to make the 30 GB ext4 and 20 GB xfs partitions).


POST FEDORA INSTALL:
1) Grab setup_project.sh from here
2) chmod +x setup_project.sh
./setup_project.sh

Step 2: Verification ChecksBefore running the grading script, run these checks to confirm the key items:   Verify Mounts:Bashdf -hT /data1 /data2
Verification: /data1 should display as ext4 (~30 GB), and /data2 should display as xfs (~20 GB).   Verify File Permissions and Attributes:Bashls -l /data1/gitstuff/bluetooth.txt
lsattr /data1/gitstuff/bluetooth.txt
Verification: Permissions must show -r-------- owned by bob:bob. The lsattr command should show the a flag (append-only).   Verify Cron Schedule:Bashcrontab -l
Verification: Shows 45 21 * * 5 tar -czf /gitstuff-backup.tar.gz -C /data1 gitstuff.   Step 3: Remaining Manual Tasks for Full MarksUpload Document via FileZilla (Step 8):Connect to your VM IP from Windows using FileZilla with username woot.   Transfer the assignment document (IT2C(LinuxAd)-Assignment2-v1.0.pdf or .docx) into /home/woot/Documents/.   Run the Official Test Script (Step 9):Exit root mode back to woot:   Bashexit
Maximize the GNOME Terminal window so it covers the entire screen.   Execute the script:   Bashwget https://triosdevelopers.com/jason.eckert/trios/linuxprojectscript.sh
chmod 755 linuxprojectscript.sh
sudo ./linuxprojectscript.sh
Take your full Windows desktop screenshot (linuxprojectscreenshot.png) and collect linuxproject.txt for submission.   
