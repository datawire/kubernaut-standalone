#!/usr/bin/env bash
set -euxo pipefail

# Kubelet wants the full hostname
hostname $(hostname -f)

# Make sure the DNS name is lowercase
CLUSTER_DNS_NAME=$(echo "${CLUSTER_DNS_NAME}" | tr 'A-Z' 'a-z')

# Initialize the master
cat >/tmp/kubeadm.yaml <<EOF
---
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
token: ${KUBEADM_TOKEN}
cloudProvider: aws
kubernetesVersion: v${KUBERNETES_VERSION}
apiServerCertSANs:
- ${CLUSTER_DNS_NAME}
EOF

kubeadm reset
kubeadm init --config /tmp/kubeadm.yaml
rm /tmp/kubeadm.yaml

export KUBECONFIG=/etc/kubernetes/admin.conf

# Flannel
# TODO: Internal -> External Networking Still Does not work
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel-rbac.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Allow containers to run on the Kubernetes Master
kubectl taint nodes --all node-role.kubernetes.io/master-

# Allow load balancers to route traffic to the Kubernetes Master
kubectl label nodes --all node-role.kubernetes.io/master-

# Allow the user to administer the cluster
kubectl create clusterrolebinding admin-cluster-binding --clusterrole=cluster-admin --user=admin

# Prepare the Kubeconfig for export
export KUBECONFIG_OUTPUT=/home/centos/kubeconfig
kubeadm alpha phase kubeconfig client-certs \
  --client-name admin \
  --server "https://${CLUSTER_DNS_NAME}:6443" \
  > "$KUBECONFIG_OUTPUT"

chown centos:centos "$KUBECONFIG_OUTPUT"
chmod 0600 "$KUBECONFIG_OUTPUT"

