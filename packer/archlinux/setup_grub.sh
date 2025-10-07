#!/usr/bin/env bash
echo "[INFO] Regenerate initramfs";
mkinitcpio -P
echo "[INFO] Installing Grub at /boot";
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCHLINUX
echo "[INFO] running grub-mkconfig"
grub-mkconfig -o /boot/grub/grub.cfg
echo "[INFO] grub configuration completed.";
