#!/usr/bin/env bash
if [ -f "/tmp/install_disk_prefix.sh" ]; then
    . "/tmp/install_disk_prefix.sh";
    rm -f "/tmp/install_disk_prefix.sh";
else
    DISK_PREFIX="sda"
fi;
echo "[INFO] Regenerate initramfs";
echo "KEYMAP=us" | sudo tee /etc/vconsole.conf
echo "FONT=Lat2-Terminus16" | sudo tee -a /etc/vconsole.conf
mkinitcpio -P
echo "[INFO] Installing Grub at /dev/${DISK_PREFIX}";
grub-install --target=i386-pc /dev/${DISK_PREFIX};
echo "[INFO] running grub-mkconfig"
grub-mkconfig -o /boot/grub/grub.cfg
echo "[INFO] grub configuration completed.";

