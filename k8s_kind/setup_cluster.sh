#!/usr/bin/env bash
KIND=$(which kind);
DOCKER=$(which docker);
PODMAN=$(which podman);
KUBECTL=$(which kubectl);
KIND_CLUSTER_NAME="k8s-nginx-cluster";
IMAGE_NAME="k8_kind_nginx";
IMAGE_TAG="latest";
DOCKERFILE="web_server/Dockerfile";
declare -i exit_status;
if [ -x /usr/bin/sw_vers ]; then
    OS_TYPE="$(sw_vers -productName)";
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE="${ID}";
fi;
if [ -n "${PODMAN}" ]; then
    DOCKER="${PODMAN}";
    IMAGE_NAME="localhost/k8_kind_nginx";
    DOCKERFILE="web_server/Containerfile";
fi;
if [ -n "${KIND}" ] && [ -n "${DOCKER}" ] && [ -n "${KUBECTL}" ]; then
    ${KIND} delete cluster --name "${KIND_CLUSTER_NAME}"
    # See if image exits";
    if ${DOCKER} images | grep -q "${IMAGE_NAME}"; then
	echo "[INFO] image ${IMAGE_NAME} exists" 1>&2;
    else
    ${DOCKER} build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "${DOCKERFILE}" .
    fi;
    if ${KIND} get clusters | grep -q "${KIND_CLUSTER_NAME}"; then
	echo "[INFO] Cluster ${KIND_CLUSTER_NAME} exists" 1>&2;
    else
	${KIND} create cluster --config nginx-cluster.yaml --name "${KIND_CLUSTER_NAME}";
    fi;

    # Find the Docker container name for the control-plane node
    KIND_NODE_CONTAINER=$(${DOCKER} ps --filter "name=${KIND_CLUSTER_NAME}-control-plane" --format "{{.Names}}")

    # Check if the node container was found
    if [ -z "$KIND_NODE_CONTAINER" ]; then
	echo "[ERROR] Control plane node for cluster \"${KIND_CLUSTER_NAME}\" not found." 1>&2;
	exit 1
    fi;
    ${KIND} load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${KIND_CLUSTER_NAME}";
    echo "[INFO] Found kind node container: $KIND_NODE_CONTAINER" 1>&2;

    # Use docker exec to run crictl inside the node and check for the image
    ${DOCKER} exec "$KIND_NODE_CONTAINER" crictl images;
    if ${DOCKER} exec "$KIND_NODE_CONTAINER" crictl images | grep -q "${IMAGE_NAME}"; then
	echo "[INFO] Image '${IMAGE_NAME}' is present on the cluster." 1>&2;
    else
	echo "[ERROR] Image '${IMAGE_NAME}' is NOT present on the cluster."  1>&2;
	exit 1
    fi;
    ${KUBECTL} cluster-info --context kind-${KIND_CLUSTER_NAME}
    if [ -z "${KIND}" ]; then
	echo "[ERROR] kind is not installed on the system" 1>&2;
    fi;
    if [ -z "${DOCKER}" ]; then
	echo "[ERROR] docker is not installed on the system" 1>&2;
    fi;
    if [ -z "${KUBECTL}" ]; then
	echo "[ERROR] kubectl is not installed on the system." 1>&2;
    fi;
    exit_status=1;
fi;
exit ${exit_status};
