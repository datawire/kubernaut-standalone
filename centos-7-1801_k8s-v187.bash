#!/usr/bin/env bash
set -euxo pipefail

KUBERNETES_VERSION=1.8.7
KUBECTL_VERSION=1.8.7

# ----------------------------------------------------------------------------------------------------------------------
# Update system software and install required dependencies
# ----------------------------------------------------------------------------------------------------------------------
yum -y update

yum -y install epel-release
yum -y install \
    curl \
    yum-utils \
    device-mapper-persistent-data \
    lvm2 \
    python-pip

# Update pip and install AWS CLI
pip install -U pip awscli

# AWS metadata tool
curl -O https://s3.amazonaws.com/ec2metadata/ec2-metadata
mv ec2-metadata /usr/bin/ec2-metadata
chmod 0755 /usr/bin/ec2-metadata

# ----------------------------------------------------------------------------------------------------------------------
# Configure Docker and Kubeadm Yum repositories
# ----------------------------------------------------------------------------------------------------------------------

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum makecache -y fast

# ----------------------------------------------------------------------------------------------------------------------
# Install Docker, Kubeadm and Kubectl
# ----------------------------------------------------------------------------------------------------------------------

yum install -y \
    docker-ce \
    docker-ce-selinux \
    kubelet-${KUBERNETES_VERSION} \
    kubeadm-${KUBERNETES_VERSION} \
    kubernetes-cni

curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl

# Add centos to the Docker user group
usermod -aG docker centos
# ----------------------------------------------------------------------------------------------------------------------
# Kubeadm has buggy configuration. Fix some stuff
# ----------------------------------------------------------------------------------------------------------------------
sed -i 's/--cgroup-driver=systemd/--cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sed -i '/Environment="KUBELET_CGROUP_ARGS/i Environment="KUBELET_CLOUD_ARGS=--cloud-provider=aws"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sed -i 's/$KUBELET_CGROUP_ARGS/$KUBELET_CLOUD_ARGS $KUBELET_CGROUP_ARGS/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# ----------------------------------------------------------------------------------------------------------------------
# Final configuration
# ----------------------------------------------------------------------------------------------------------------------
mkdir /etc/kubernaut
printf "%s" "$KUBERNETES_VERSION" > /etc/kubernaut/kubernetes_version
printf "%s" "$KUBECTL_VERSION" > /etc/kubernaut/kubectl_version
chmod 0755 /etc/kubernaut/*

# ensure br_netfilter is loaded at boot
echo br_netfilter > /etc/modules-load.d/br_netfilter.conf

modprobe br_netfilter
echo "$(sysctl -w net.bridge.bridge-nf-call-iptables=1)" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
