#!/bin/bash
set -e

#======================================================
# https://degencoder.com
#=====================================================

DISK=”/dev/nvme0n1″
HOSTNAME=”your_hostname”
USERNAME=”your_username”
EDITOR=”nano”
TIMEZONE=”America/New_York”

ssid=”your_wifi_name”
wifipass=”your_wifi_password”

echo “[+] Starting Wi-Fi setup using iwd…”
systemctl start iwd
sleep 1

device=$(iwctl device list | awk ‘NR> 4 && $2 != “” {print $2; exit}’)
if [ -z “$device” ]; then
    echo “[!] No wireless device found.”
    exit 1
fi

iwctl station “$device” scan
sleep 3
iwctl station “$device” get-networks

echo “$wifipass” | iwctl –passphrase “$wifipass” station “$device” connect “$ssid”

echo “[+] Establishing connection…”
sleep 5

echo “[+] Time sync”
timedatectl set-ntp true
sleep 5

echo “[+] Wiping all partitions on $DISK…”
sleep 5
wipefs -a $DISK
sgdisk –zap-all $DISK

sgdisk -n1:0:+1G  -t1:ef00   -c1:EFI $DISK
sgdisk -n2:0:+50G  -t2:8300   -c2:ROOT $DISK
sgdisk -n3:0:+100G    -t3:8300   -c3:HOME $DISK
sgdisk -n4:0:0    -t4:8300   -c4:DATA $DISK

# Refresh partition table
partprobe “$DISK”

efi_part=”${DISK}p1″
root_part=”${DISK}p2″
home_part=”${DISK}p3″
data_part=”${DISK}p4″

mkfs.fat -F32 $efi_part
mkfs.ext4 -F $root_part
mkfs.ext4 -F $home_part
mkfs.ext4 -F $data_part

mount $root_part /mnt

mkdir -p /mnt/boot
mount $efi_part /mnt/boot

mkdir -p /mnt/home
mount $home_part /mnt/home

mkdir -p /mnt/data
mount $data_part /mnt/data

echo “[+] Installing base system and packages…”
sleep 5
pacstrap -K /mnt base linux linux-firmware grub efibootmgr sudo xfce4 xfce4-goodies lightdm lightdm-gtk-greeter networkmanager \
   || {
      echo “[!] packstrap failed – initialising keyring…”
      sleep 5
      pacman-key –init
      pacman-key –populate archlinux

      echo “[+] Retrying packstrap…”
      sleep 5
      pacstrap -K /mnt base linux linux-firmware grub efibootmgr sudo xfce4 xfce4-goodies lightdm lightdm-gtk-greeter networkmanager
      }

> /mnt/etc/fstab

echo “[+] GENFSTAB…”
sleep 5
genfstab -U /mnt > /mnt/etc/fstab

echo “[+] Entering chroot to configure system…”
arch-chroot /mnt /bin/bash <<EOF
sleep 5

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock –systohc
sed -i ‘s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/’ /etc/locale.gen
locale-gen

echo “LANG=en_US.UTF-8” > /etc/locale.conf
echo “$HOSTNAME” > /etc/hostname
echo “127.0.0.1 localhost” >> /etc/hosts
echo “::1       localhost” >> /etc/hosts
echo “127.0.1.1 $HOSTNAME.localdomain $HOSTNAME” >> /etc/hosts

useradd -m -G wheel $USERNAME
echo “$USERNAME:$USERNAME” | chpasswd

sed -i ‘s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/’ /etc/sudoers
echo “EDITOR=$EDITOR” >> /etc/environment

systemctl enable NetworkManager
systemctl enable lightdm

mkinitcpio -P

grub-install –target=x86_64-efi –efi-directory=/boot –bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF
sleep 5

echo “[✓] Installation complete! Reboot and log in as ‘$USERNAME’.”
echo “[→] LightDM will start XFCE automatically.”
