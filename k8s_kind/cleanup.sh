#!/usr/bin/env bash
KIND_CLUSTER_NAME="k8s-nginx-cluster";

kind delete cluster --name "${KIND_CLUSTER_NAME}"


