#!/usr/bin/env bash
declare -i exit_status=0;
if [ -x /usr/bin/sw_vers ]; then
    OS_TYPE="$(sw_vers -productName)";
    OS_VERSION="$(sw_vers -productVersion)";
    NAME_STRING="${OS_TYPE} ${OS_VERSION}";
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE="${ID}";
    NAME_STRING="${PRETTY_NAME}";
fi;
# Use the provider environment variable
# group does not support the provider switch.
#
VAGRANT_DEFAULT_PROVIDER="virtualbox";
VALID_OPTIONS=":hp:"

VOX_SERVER_IP="";
VOX_SERVER_NAME="vox_server";
VOX_SERVER_HOST_NAME="vox-server";
VOX_CLIENT_NAME="vox_client";
VOX_CLIENT_HOST_NAME="vox-client";
WAIT_TIME=30;
declare -a valid_providers=("virtualbox" "vmware_fusion" "vmware_desktop" "libvirt");
VAGRANT=$(which vagrant);
display_help() {
    echo "setup_voxdev.sh [h] [p provider]";
    echo "-h - display this message";
    echo "-p - provider (virtualbox, vmware_fusion, vmware_desktop, libvirt)."
};

while getopts "${VALID_OPTIONS}" cur_opt;
do
    case ${cur_opt} in
	 h)
	     display_help;
	     exit_status=2;
	     break;
	   ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    exit_status=1
	    break
	    ;;
	p)
	    VAGRANT_DEFAULT_PROVIDER="$OPTARG";
	    ;;
       :)
	   echo "Option -$OPTARG requires an argument." >&2
	   exit_status=1
	   break
	   ;;
    esac;
done;
shift $((OPTIND - 1));
if [ -n "${VAGRANT}" ]  && [ ${exit_status} -eq 0 ]; then
    pattern="(^| )($VAGRANT_DEFAULT_PROVIDER)( |$)";
    provider_valid=1;
    if [[ " ${valid_providers[@]} " =~ $pattern ]]; then
	echo "[INFO] Using provider: ${VAGRANT_DEFAULT_PROVIDER}" 1>&2;
	export VAGRANT_DEFAULT_PROVIDER;
	provider_valid=0;
    else
	echo "[ERROR] Provider: '$VAGRANT_DEFAULT_PROVIDER' is not valid/supported." 1>&2;
    fi;
    if [ "${VAGRANT_DEFAULT_PROVIDER}" == "libvirt" ]; then
       cd libvirt;
    fi;
    if [ ${provider_valid} -eq 0 ]; then
       ${VAGRANT} group up voxdevelopment;
       VOX_SERVER_IP=$(${VAGRANT} ssh ${VOX_SERVER_NAME} -- ip -4 addr show eth1 | grep inet | awk '{print $2}' | cut -d/ -f1);
       if [ -n "${VOX_SERVER_IP}" ]; then
	   VOX_CLIENT_IP=$(${VAGRANT} ssh ${VOX_CLIENT_NAME} -- ip -4 addr show eth1 | grep inet | awk '{print $2}' | cut -d/ -f1);
	   echo "[INFO] vox server host only ip address: ${VOX_SERVER_IP}" 1>&2;
	   tmp_file="$(mktemp)";
	   case "${VAGRANT_DEFAULT_PROVIDER}" in
	       virtualbox|libvirt)
		   printf "#!/usr/bin/env bash\nprintf \"${VOX_SERVER_IP} puppet\\\n${VOX_CLIENT_IP} ${VOX_CLIENT_HOST_NAME}\\\n\" >> /etc/hosts\n" >> "${tmp_file}";
		   ;;
	       vmware_fusion)
		   printf "#!/usr/bin/env bash\nprintf \"${VOX_SERVER_IP} puppet\\\n${VOX_CLIENT_IP} ${VOX_CLIENT_HOST_NAME}\\\n\" >> /etc/hosts\n" >> "${tmp_file}";
		   ;;
	       *)
		   printf "#!/usr/bin/env bash\nprintf \"${VOX_SERVER_IP} puppet\\\n${VOX_CLIENT_IP} ${VOX_CLIENT_HOST_NAME}\\\n\" >> /etc/hosts\n" >> "${tmp_file}";
		   ;;
	   esac;
	   chmod a+x "${tmp_file}";
	   ${VAGRANT} scp "${tmp_file}" ${VOX_SERVER_NAME}:./configure_hosts.sh;
	   ${VAGRANT} ssh ${VOX_SERVER_NAME} -c "sudo ./configure_hosts.sh";
	   rm -f "${tmp_file}";
	   tmp_file="$(mktemp)";
	   # Configure Client
	   VOX_SERVER_DOMAIN_NAME="${VOX_SERVER_HOST_NAME}";
	   #
	   # VMware Fusion and virtualbox hand internal DNS and hosts names differently.
	   #
	   case "${VAGRANT_DEFAULT_PROVIDER}" in
	       virtualbox|libvirt)
		   printf "#!/usr/bin/env bash\nprintf \"${VOX_SERVER_IP} ${VOX_SERVER_HOST_NAME} puppet\\\n\" >> /etc/hosts\n" >> "${tmp_file}";
		   ;;
	       vmware_fusion)
		   printf "#!/usr/bin/env bash\nprintf \"${VOX_SERVER_IP} ${VOX_SERVER_HOST_NAME} puppet ${VOX_SERVER_HOST_NAME}.localdomain\\\n\" >> /etc/hosts\n" >> "${tmp_file}";
		   VOX_SERVER_DOMAIN_NAME="${VOX_SERVER_HOST_NAME}.localdomain";
		   ;;
	       *)
		   printf "#!/usr/bin/env bash\nprintf \"${VOX_SERVER_IP} ${VOX_SERVER_HOST_NAME} puppet\\\n\" >> /etc/hosts\n" >> "${tmp_file}";
		   ;;
	   esac;
	   chmod a+x "${tmp_file}";
	   ${VAGRANT} scp "${tmp_file}" ${VOX_CLIENT_NAME}:./configure_hosts.sh;
	   ${VAGRANT} ssh ${VOX_CLIENT_NAME} -c "sudo ./configure_hosts.sh";
	   rm -f "${tmp_file}";
	   ${VAGRANT} ssh ${VOX_CLIENT_NAME} -c "sudo puppet config set server ${VOX_SERVER_DOMAIN_NAME} --section agent";
	   # Restart the puppet agent service so that it requests a certificate.
	   ${VAGRANT} ssh ${VOX_CLIENT_NAME} -c "sudo systemctl restart puppet;"
	   echo "[INFO] Wait ${WAIT_TIME} seconds for client system to contact server." 1>&2;
	   sleep ${WAIT_TIME};
	   echo "[INFO] Checking Server for cert siging request." 1>&2;
	   ${VAGRANT} ssh ${VOX_SERVER_NAME} -c "sudo puppetserver ca list --all";
	   ${VAGRANT} ssh ${VOX_SERVER_NAME} -c "sudo puppetserver ca sign --all";
	   echo "[INFO] Wait ${WAIT_TIME} seconds for client system to sync with server." 1>&2;
	   sleep ${WAIT_TIME};
	   ${VAGRANT} ssh ${VOX_CLIENT_NAME} -c "sudo puppet agent --test";
	   echo "[INFO] Checking that emacs is installed." 1>&2;
	   ${VAGRANT} ssh ${VOX_CLIENT_NAME} -c "which emacs";
	   echo "[INFO] The development environment is now ready to use." 1>&2;
	   exit_status=0;
       else
	   echo "[ERROR] Unable to locate vox server host only ip address." 1>&2;
       fi;
    fi;
else
if [ ${exit_status} -ne 2 ]; then
    echo "[ERROR] vagrant command not found." 1>&2;
fi;
fi;
if [ ${exit_status} -eq 2 ]; then
    exit_status=0;
fi;
exit ${exit_status};
