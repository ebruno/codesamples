#!/usr/bin/env bash
declare -i exit_status=0;
declare -i wait_delay=4;
KIND_CLUSTER_NAME="k8s-nginx-cluster";
IMAGE_NAME="k8_kind_nginx";
IMAGE_TAG="latest";
DEPLOYMENT_NAME="nginx-deployment";
DEPLOYMENT_FILE="${DEPLOYMENT_NAME}.yaml"
SERVICE_FILE="nginx-service.yaml"
if [ -x /usr/bin/sw_vers ]; then
    OS_TYPE="$(sw_vers -productName)";
    OS_VERSION="$(sw_vers -productVersion)";
    NAME_STRING="${OS_TYPE} ${OS_VERSION}";
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE="${ID}";
    NAME_STRING="${PRETTY_NAME}";
fi;
KIND=$(which kind);
DOCKER=$(which docker);
KUBECTL=$(which kubectl);
PODMAN=$(which podman);

check_deployment () {
# param 1 file name containing the deployment information.
    local -i REQUIRED_PARAMS=1;
    local -i local_exit_status=1;
    local -a avail_status;
    local -a progress_status;
    if [ $# -eq 1 ]; then
	if [ -f "${1}" ]; then
	    while read -r line; do
		if [[ "${line}" =~ ^Available.* ]]; then
		    read -a avail_status <<< ${line};
		elif [[ "${line}" =~ ^Progressing.* ]]; then
		    read -a progress_status <<< ${line};
		fi;
	    done < "${1}";
	    if [ ${#avail_status[*]} -eq 3 ] && [ ${#progress_status[*]} -eq 3 ]; then
		if [ "${avail_status[1]}" = "True" ] && [ "${progress_status[1]}" = "True" ]; then
		    local_exit_status=0;
		    log_severity="[INFO]"
		else
		    log_severity="[WARNING]"
		fi;
		echo "${log_severity} Deployment condition: ${avail_status[0]} ${avail_status[1]} ${avail_status[2]}" 1>&2;
		echo "${log_severity} Deployment condition: ${progress_status[0]} ${progress_status[1]} ${progress_status[2]}" 1>&2;
	    else
		echo "[ERROR] Unable to determine deployment status";
            fi;
	else
	    echo "[ERROR] \"${FUNCNAME[0]}\" file \"${1}\" does not exist." 1>&2;
	fi;
    else
	echo "[ERROR] \"${FUNCNAME[0]}\" requires ${REQUIRED_PARAMS} parameter $# passed." 1>&2;
    fi;	   
    return ${local_exit_status};
};

if [ -n "${PODMAN}" ]; then
    DOCKER="${PODMAN}";
    IMAGE_NAME="localhost/k8_kind_nginx";
    DEPLOYMENT_FILE="nginx-deployment-podman.yaml"
fi;

if [ -n "${KIND}" ] && [ -n "${DOCKER}" ] && [ -n "${KUBECTL}" ]; then
    echo "[INFO] Deploying on ${NAME_STRING}";
    if ${KIND} get clusters | grep -q "${KIND_CLUSTER_NAME}"; then
       echo "[INFO] Cluster ${KIND_CLUSTER_NAME} exists" 1>&2;

       # Determine the Docker container name for the control-plane node
       KIND_NODE_CONTAINER=$(${DOCKER} ps --filter "name=${KIND_CLUSTER_NAME}-control-plane" --format "{{.Names}}")

       # Valdiate the node container was found
       if [ -z "$KIND_NODE_CONTAINER" ]; then
	   echo "[ERROR] Control plane node for cluster '${KIND_CLUSTER_NAME}' not found." 1>&2;
	   exit_status=1;
       else
	   echo "[INFO] Found kind node container: $KIND_NODE_CONTAINER" 1>&2;
	   if ${DOCKER} exec "$KIND_NODE_CONTAINER" crictl images | grep -q "${IMAGE_NAME}"; then
	       echo "[INFO] Image '${IMAGE_NAME}' is present on the cluster." 1>&2;
	       ${KUBECTL} apply -f "${DEPLOYMENT_FILE}";
	       ${KUBECTL} apply -f "${SERVICE_FILE}";
	       ${KUBECTL} get service nginx-service;
	       tmp_file="$(mktemp)";
	       max_check=6;
	       while [ ${max_check} -gt 0 ]; do
		   ${KUBECTL} describe deployment "${DEPLOYMENT_NAME}" > "${tmp_file}";
		   check_deployment "${tmp_file}";
		   if [ $? -eq 0 ]; then
		       curl http://localhost:30080;
                       if [ $? -eq 0 ]; then
			   break;
		       fi;
		   else
		       echo "[WARNING] deployment is not ready ${max_check} checks left.";
		   fi;
		   sleep ${wait_delay};
		   ((--max_check));
	       done;
	       if [ ${max_check} -eq 0 ]; then
		   echo "[ERROR] Deployment ${DEPLOYMENT_NAME} is not ready.";
		   exit_status=1;
	       fi;
	       rm -f "${tmp_file}";
	   else
	       echo "[ERROR] Image \"${IMAGE_NAME}\" is NOT present on the cluster."  1>&2;
	       exit_status=1;
	   fi;
       fi;
    else
       echo "[ERROR] Cluster ${KIND_CLUSTER_NAME} does not exist." 1>&2;
    fi;
else
    if [ -z "${KIND}" ]; then
	echo "[ERROR] kind is not installed on the system." 1>&2;
    fi;
    if [ -z "${DOCKER}" ]; then
	echo "[ERROR] docker is not installed on the system." 1>&2;
    fi;
    if [ -z "${KUBECTL}" ]; then
	echo "[ERROR] kubectl is not installed on the system." 1>&2;
    fi;
    exit_status=1;
fi;

exit ${exit_status};
