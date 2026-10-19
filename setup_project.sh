#!/bin/bash
set -e

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (use 'su -' first)."
  exit 1
fi

STUDENT_NAME="Matt Slaunwhite"
BOB_PASS="Password123!"

echo "[+] Starting automated configuration for Steps 4 - 8..."

# ==============================================================================
# Step 4: Storage Configuration on /dev/sdb
# ==============================================================================
echo "[+] Step 4: Partitioning and mounting /dev/sdb..."

# 4a & 4b: Partition /dev/sdb (30GB partition 1, remaining ~20GB partition 2)
parted -s /dev/sdb mklabel msdos
parted -s /dev/sdb mkpart primary ext4 1MiB 30721MiB
parted -s /dev/sdb mkpart primary xfs 30721MiB 100%
udevadm settle

# Format partitions
mkfs.ext4 -F /dev/sdb1
mkfs.xfs -f /dev/sdb2

# Create mount points and mount
mkdir -p /data1 /data2
mount /dev/sdb1 /data1
mount /dev/sdb2 /data2

# 4c: Edit /etc/fstab for persistence
UUID1=$(blkid -s UUID -o value /dev/sdb1)
UUID2=$(blkid -s UUID -o value /dev/sdb2)

# Remove any old entries for /data1 or /data2 if re-running
sed -i '/\/data1/d' /etc/fstab
sed -i '/\/data2/d' /etc/fstab

echo "UUID=$UUID1 /data1 ext4 defaults 0 2" >> /etc/fstab
echo "UUID=$UUID2 /data2 xfs defaults 0 0" >> /etc/fstab

# 4d: Copy /etc/ssh to /data2
cp -a /etc/ssh /data2/

# ==============================================================================
# Step 5: Shell, File, Git, User, and Cron Operations
# ==============================================================================
echo "[+] Step 5: Setting up Git, users, cron, and file permissions..."

# 5a & 5b: Git directory and initialization
mkdir -p /data1/gitstuff
cd /data1/gitstuff
git init
git config --global user.name "$STUDENT_NAME"
git config --global user.email "matt@slaunwhite.com"

# 5c: Baseline vmstat
vmstat > /data1/gitstuff/baseline.txt

# 5d: Find all sshd_config files
find / -name "sshd_config" > /data1/gitstuff/sshconfigs.txt 2>/dev/null

# 5e: Bluetooth errors from journal (fallback to broad search if no critical errors)
journalctl -p err..emerg | grep -i "bluetooth" > /data1/gitstuff/bluetooth.txt || true
if [ ! -s /data1/gitstuff/bluetooth.txt ]; then
    journalctl | grep -i "bluetooth" > /data1/gitstuff/bluetooth.txt || true
fi

# 5f: Commit 1
git add .
git commit -m "Commit 1"

# 5g & 5h: Append line and Commit 2
echo "New line added by $STUDENT_NAME" >> /data1/gitstuff/sshconfigs.txt
git add sshconfigs.txt
git commit -m "Commit 2"

# 5i: Create cls alias in ~/.bashrc for root and woot
if ! grep -q "alias cls=" /root/.bashrc; then
    echo "alias cls='clear'" >> /root/.bashrc
fi
if [ -d "/home/woot" ] && ! grep -q "alias cls=" /home/woot/.bashrc; then
    echo "alias cls='clear'" >> /home/woot/.bashrc
fi

# 5j: Perform tar backup
tar -czf /gitstuff-backup.tar.gz -C /data1 gitstuff

# 5k: Schedule tar backup every Friday at 9:45pm (21:45)
crontab -l 2>/dev/null | grep -v "/gitstuff-backup.tar.gz" > /tmp/cron.tmp || true
echo "45 21 * * 5 tar -czf /gitstuff-backup.tar.gz -C /data1 gitstuff" >> /tmp/cron.tmp
crontab /tmp/cron.tmp
rm -f /tmp/cron.tmp

# 5l, 5m, 5n: Create user bob, password, and wheel membership
if ! id "bob" &>/dev/null; then
    useradd -G wheel bob
else
    usermod -aG wheel bob
fi
echo "bob:$BOB_PASS" | chpasswd

# 5o, 5p, 5q: Ownership, read-only permissions for bob only, append-only attribute
chown bob:bob /data1/gitstuff/bluetooth.txt
chmod 400 /data1/gitstuff/bluetooth.txt
chattr +a /data1/gitstuff/bluetooth.txt

# ==============================================================================
# Step 6: SSH Daemon Configuration
# ==============================================================================
echo "[+] Step 6: Configuring OpenSSH server..."

# Enable and start SSH service
systemctl enable --now sshd

# Allow root login via sshd_config.d drop-in
mkdir -p /etc/ssh/sshd_config.d
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/01-permitroot.conf
systemctl restart sshd

# Permanent firewall rule
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# ==============================================================================
# Step 7: Apache HTTP Server
# ==============================================================================
echo "[+] Step 7: Installing and configuring Apache..."

dnf install -y httpd mod_ssl
systemctl enable --now httpd

# Default webpage
echo "Default Apache Page from $STUDENT_NAME" > /var/www/html/index.html
chmod 644 /var/www/html/index.html

# Firewall rules for HTTP and HTTPS
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# ==============================================================================
# Step 8: Very Secure FTP Daemon (vsftpd)
# ==============================================================================
echo "[+] Step 8: Installing and configuring vsftpd..."

dnf install -y vsftpd
sed -i 's/^anonymous_enable=NO/anonymous_enable=YES/' /etc/vsftpd/vsftpd.conf
if ! grep -q "^anonymous_enable" /etc/vsftpd/vsftpd.conf; then
    echo "anonymous_enable=YES" >> /etc/vsftpd/vsftpd.conf
fi

systemctl enable --now vsftpd
systemctl restart vsftpd

# Enable SELinux FTP access if enforcing
setsebool -P ftpd_full_access 1 2>/dev/null || true

# Firewall rule for FTP
firewall-cmd --permanent --add-service=ftp
firewall-cmd --reload

echo "[+] Automation completed successfully!"
