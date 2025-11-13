#!/usr/bin/env bash
declare -i exit_status=1;
PACKER_CMD=$(which packer 2> /dev/null);
if [ -n "${PACKER_CMD}" ]; then
   if [ $# -eq 1 ]; then
       ISO_BUILD_DATE="${1}";
   else	  
       ISO_BUILD_DATE="$(date +"%Y.%m.01")";
   fi;
   if [ $# -eq 1 ]; then
       vcenter_vars="${1}";
   else
       vcenter_vars="vcenter.pkvars.hcl"
   fi;
   echo "[INFO] Using ${vcenter_vars} for vSphere/vCenter login access" 2>&1;
   packer_basename="archlinux";
   pkrvars_name="${packer_basename}.pkrvars.hcl";
   hcl_name="${packer_basename}.pkr.hcl";
   ISO_MIRROR="https://dfw.mirror.rackspace.com/archlinux/iso";
   ISO_NAME="archlinux-${ISO_BUILD_DATE}-x86_64.iso";
   if [ -f ./assets/id_rsa ]; then
       rm -f ./assets/id_rsa*;
   else
       if [ ! -d ./assets ]; then
	   mkdir assets;
       fi;
   fi;
   ssh-keygen -t rsa -b 4096 -N "" -f assets/id_rsa -C "packer_key_for_build" > /dev/null 2>&1;
   public_key="$(cat ./assets/id_rsa.pub)";
   builduser_passwd="$(echo packer | openssl passwd -6 -salt $(openssl rand -base64 16) --stdin)"
   root_passwd="$(echo packer | openssl passwd -6 -salt $(openssl rand -base64 16)  --stdin)"
   # setup pkrvars file for run.
   echo "hostname=\"archlinuxvm03\"" > "${pkrvars_name}";
   echo "iso_url=\"${ISO_MIRROR}/${ISO_BUILD_DATE}/${ISO_NAME}\"" >> "${pkrvars_name}";
   curl -s -O "${ISO_MIRROR}/${ISO_BUILD_DATE}/sha256sums.txt"
   while read -a line
   do
       if [ "${line[1]}" = "${ISO_NAME}" ]; then
	   echo "iso_checksum=\"sha256:${line[0]}\"" >> "${pkrvars_name}";
       fi;
   done < "./sha256sums.txt";
   packer init archlinux_vsphere.pkr.hcl;
   rm -r -f output/packer-archmaster;
   packer build -force  -var "public_key=${public_key}" -var-file="${pkrvars_name}" -var-file="${vcenter_vars}" archlinux_vsphere.pkr.hcl;
   exit_status=$?;
   rm -f "${pkrvars_name}";
   exit_status=0;
else
   echo "[ERROR] packer not installed." 1>&2;
fi;
exit ${exit_status};
