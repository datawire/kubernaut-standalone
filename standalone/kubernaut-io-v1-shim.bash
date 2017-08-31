#!/usr/bin/env bash
export KUBEADM_TOKEN="${kubeadm_token}"
export KUBERNETES_VERSION="$(cat /etc/kubernaut/kubernetes_version)"

curl https://raw.githubusercontent.com/datawire/kubernaut-vm-standalone/master/${bootstrap_script} | bash
