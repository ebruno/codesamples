#!/usr/bin/env bash

tmp_val=$(lsblk | grep -v fd | grep -m 1 disk);
read -a tmp_diskinfo <<< ${tmp_val};
disk_prefix="${tmp_diskinfo[0]}";
echo "[INFO] Using disk_prefix: ${disk_prefix}";
echo "[INFO] Dismounting /mnt and turning off swap partition /dev/${disk_prefix}1";
umount /mnt
swapoff /dev/${disk_prefix}1;
