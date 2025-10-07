#!/usr/bin/bash
tmp_val=$(lsblk | grep -v fd | grep -m 1 disk);
read -a tmp_diskinfo <<< ${tmp_val};
disk_prefix="${tmp_diskinfo[0]}";
echo "[INFO] Using disk_prefix: ${disk_prefix}";
ln -sf /usr/share/zoneinfo/US/Pacific /etc/localtime
hwclock --systohc
sed -i -e 's/#en_US.UTF8/en_US.UTF8/' /etc/locale.gen
local-gen
pacman -Syy --noconfirm;
pacman -Sy --noconfirm  dhcpcd dnsutils nfs-utils sudo openssh grub efibootmgr
pacman -Sy --noconfirm vim emacs
pacman -Sy --noconfirm cmake doxygen graphviz pacman
pacman -Sy --noconfirm git gitlab-runner
systemctl enable dhcpcd
systemctl enable gitlab-runner
systemctl enable sshd
# not working reliable disable for now.
#systemctl enable systemd-networkd.service systemd-networkd-wait-online.service
install /root/update_etc_issue.sh /usr/local/bin;
install -m 664 /root/show_ip_on_login.service /usr/lib/systemd/system;
# not working reliable disable for now.
#systemctl enable show_ip_on_login.service;
rm -f root/update_etc_issue.sh /root/show_ip_on_login.service;
echo "[INFO] Package install completed.";
# Gitlab-runner needs full sudo rights.
echo "gitlab-runner ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers.d/admins"
chmod 440 "/etc/sudoers.d/admins"
useradd -m -G wheel -s /bin/bash builduser;
echo "builduser ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers.d/admins"
echo "[INFO] Set password for root and builduser."
