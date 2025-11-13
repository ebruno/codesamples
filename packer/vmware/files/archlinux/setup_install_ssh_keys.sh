#!/usr/bin/env bash
declare -i exit_status=0;
for user in ${@}
do
    if [ "${user}" = "root" ]; then
       echo "[INFO] Installing public key for root" 1>&2;
       mkdir -p /root/.ssh;
       cp /root/id_rsa.pub /root/.ssh/authorized_keys;
       chmod 600 /root/.ssh/authorized_keys;
       chmod 700 /root/.ssh;
    else
	if [ -d "/home/${user}" ]; then
	    echo "[INFO] Installing public key for ${user}" 1>&2;
	    mkdir -p /home/${user}/.ssh;
	    cp /root/id_rsa.pub /home/${user}/.ssh/authorized_keys;
	    chown ${user}:${user} /home/${user}/.ssh;
	    chown ${user}:${user} /home/${user}/.ssh/authorized_keys;
	    chmod 600 /home/${user}/.ssh/authorized_keys;
	    chmod 700 /home/${user}/.ssh;
	else
	    echo "[ERROR] Home directory for ${user} does not exist." 1>&2;
	    exit_status=1;
	    continue;
	fi;
    fi;
done;
rm -f /root/id_rsa.pub;
exit ${exit_status};
