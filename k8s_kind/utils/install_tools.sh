#!/usr/bin/env bash

. /etc/os-release;
declare -i exit_status=0;
KIND_INSTALL_DIR="/usr/local/bin";

if [ "${ID}" = "fedora" ] || [ "${ID}" = "debian" ]; then
    KIND=$(which kind);
    if [ -z "${KIND}" ]; then
	if [ $(uname -m) = x86_64 ]; then
	    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64;
	elif [ $(uname -m) = aarch64 ]; then
	    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-arm64;
	fi;
	if [ -f ./kind ]; then
	    chmod +x ./kind
	    sudo mv ./kind ${KIND_INSTALL_DIR}/kind
	    echo "[INFO] Installed kind in ${KIND_INSTALL_DIR}" 1>&2;
	fi;
    else
	echo "[INFO] ${VERSION_CODENAME} ${ID} kind is currently installed, skipping install." 1>&2;
    fi;
else
    echo "[WARNING] ${VERSION_CODENAME} ${ID} is not currently supported, skipping kind install." 1>&2;
    exit_status=1;
fi;
if [ "${ID}" = "fedora" ]; then
    if [ ! -f /etc/yum.repos.d/kubernetes.repo ]; then
       sudo tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF
    else
	echo "[INFO] ${VERSION_CODENAME} ${ID} repo definition is already present, skipping install." 1>&2;
    fi;
    sudo dnf update;
    sudo dnf install -y kubectl;
elif [ "${ID}" = "debian" ]; then
    sudo apt-get update;
    sudo apt-get -y install kubectl;
else
    echo "[WARNING] ${VERSION_CODENAME} ${ID} is not currently supported, skipping kubectl install." 1>&2;
    exit_status=1;
fi;
exit ${exit_status};
