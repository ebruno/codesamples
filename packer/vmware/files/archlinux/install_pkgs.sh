#!/usr/bin/bash
if [ $# -eq 1 ]; then
    admin_user="${1}";
else
    admin_user="packer";
fi;
tmp_val=$(lsblk | grep -v fd | grep -m 1 disk);
read -a tmp_diskinfo <<< ${tmp_val};
disk_prefix="${tmp_diskinfo[0]}";
echo "[INFO] Using disk_prefix: ${disk_prefix}";
ln -sf /usr/share/zoneinfo/US/Pacific /etc/localtime
hwclock --systohc
sed -i -e 's/#en_US.UTF8/en_US.UTF8/' /etc/locale.gen
local-gen
pacman -Syy --noconfirm;
pacman -Sy --noconfirm  dhcpcd dnsutils nfs-utils sudo openssh grub
pacman -Sy --noconfirm vim emacs-nox
pacman -Sy --noconfirm git open-vm-tools
systemctl enable dhcpcd
systemctl enable vmtoolsd
systemctl enable sshd
# not working reliable disable for now.
#systemctl enable systemd-networkd.service systemd-networkd-wait-online.service
install /root/update_etc_issue.sh /usr/local/bin;
install -m 664 /root/show_ip_on_login.service /usr/lib/systemd/system;
# not working reliable disable for now.
# systemctl disable show_ip_on_login.service;
rm -f root/update_etc_issue.sh /root/show_ip_on_login.service;
echo "[INFO] Package install completed.";
chmod 440 "/etc/sudoers.d/admins"
useradd -m -G wheel -s /bin/bash ${admin_user};
echo "${admin_user} ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers.d/admins"
echo "[INFO] Set password for root and ${admin_user}."
