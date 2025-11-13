#!/usr/bin/bash
if [ $# -eq 1 ]; then
    disk_prefix="${1}";
    lsblk | grep -m 1 "disk" | grep -q "${disk_prefix}";
    if [ ! $? -eq 0 ]; then
	echo "[ERROR] specified prefix \"${disk_prefix}\" not found."
	exit 1;
    fi;
else
    tmp_val=$(lsblk | grep -v fd | grep -m 1 disk);
    read -a tmp_diskinfo <<< ${tmp_val};
    disk_prefix="${tmp_diskinfo[0]}"
fi;
echo DISK_PREFIX="${disk_prefix}" > /tmp/install/install_disk_prefix.sh;
echo "[INFO] Using disk prefix \"${disk_prefix}\"" 1>&2;
timedatectl set-ntp true
pacman -Syy --noconfirm
pacman -Sy --noconfirm vim
sfdisk /dev/${disk_prefix} << EOF
label: dos
label-id: 0xfd3433dc
device: /dev/${disk_prefix}
unit: sectors
sector-size: 512

/dev/${disk_prefix}1 : start=        2048, size=8388608     , type=82
/dev/${disk_prefix}2 : start=     8390656, size=+           , type=83, bootable
EOF
sfdisk -l /dev/${disk_prefix};
mkfs.ext4 /dev/${disk_prefix}2;
mkswap /dev/${disk_prefix}1 ;
swapon /dev/${disk_prefix}1;
mount /dev/${disk_prefix}2 /mnt;
pacstrap /mnt base base-devel linux linux-firmware;
genfstab -U /mnt >> /mnt/etc/fstab;
cp /tmp/install/* /mnt/root;
echo "[INFO] Phase 1 install completed";
