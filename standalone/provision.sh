#!/usr/bin/env bash
export KUBEADM_TOKEN="${kubeadm_token}"
export KUBERNETES_VERSION="$(cat /etc/kubernaut/kubernetes_version)"
export KUBERNETES_NETWORKING="${kubernetes_networking_plugin}"

export CLUSTER_NAME="${cluster_name}"
export CLUSTER_DNS_NAME="${cluster_dns_name}"

curl https://raw.githubusercontent.com/datawire/kubernaut-standalone/master/kubeadm-$${KUBERNETES_NETWORKING}.bash | bash
