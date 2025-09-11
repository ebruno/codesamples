#!/usr/bin/env bash
declare -i exit_status=0;
KIND_CLUSTER_NAME="k8s-nginx-cluster";
IMAGE_NAME="k8_kind_nginx";
IMAGE_TAG="latest";
if [ -x /usr/bin/sw_vers ]; then
    OS_TYPE="$(sw_vers -productName)";
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE="${ID}";
fi;
KIND=$(which kind);
DOCKER=$(which docker);
KUBECTL=$(which kubectl);

if [ -n "${KIND}" ] && [ -n "${DOCKER}" ] && [ -n "${KUBECTL}" ]; then
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

	   # Use docker exec to run crictl inside the node and check for the image
	   ${DOCKER} exec "$KIND_NODE_CONTAINER" crictl images;
	   if ${DOCKER} exec "$KIND_NODE_CONTAINER" crictl images | grep -q "${IMAGE_NAME}"; then
	       echo "[INFO] Image '${IMAGE_NAME}' is present on the cluster." 1>&2;
	       ${KUBECTL} apply -f nginx-deployment.yaml
	       ${KUBECTL} apply -f nginx-service.yaml
	       ${KUBECTL} get deployment nginx-deployment
	       ${KUBECTL} get service nginx-service
	       echo "[INFO] Wait 20 seconds for the service to settle." 1>&2;
	       sleep 20;
	       curl http://localhost:30080
	   else
	       echo "[ERROR] Image '${IMAGE_NAME}' is NOT present on the cluster."  1>&2;
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
