#!/usr/bin/env bash
set -euxo pipefail

# Kubelet wants the full hostname
hostname $(hostname -f)

# Point a Route53 record at the DNS name
public_hostname=$(ec2-metadata | sed 's/public-hostname: //' | tr -d '\n')
instance_id=$(ec2-metadata | sed 's/instance-id: //' | tr -d '\n')

kubernaut_r53_zone_id=$(aws route53 list-hosted-zones --query 'HostedZones[?Name==`kubernaut.io.`].Id' --output text | sed 's|/hostedzone/||')
CLUSTER_DNS_NAME="${instance_id}.kubernaut.io"
aws route53 change-resource-record-sets \
    --hosted-zone-id ${kubernaut_r53_zone_id} \
    --change-batch "{\"Changes\": [{\"Action\": \"CREATE\", \"ResourceRecordSet\": {\"Name\": \"$CLUSTER_DNS_NAME\", \"Type\": \"CNAME\", \"TTL\": 60, \"ResourceRecords\": [{\"Value\": \"$public_hostname\"} ] } } ] }"

# This is a bit of a hack but I do not feel like mucking with Systemd unit file ordering right now to ensure the
# cloud-final unit runs after the docker.service unit.
systemctl enable docker
systemctl start docker

systemctl enable kubelet
systemctl start kubelet
sleep 5s

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

# Calico
kubectl apply -f https://raw.githubusercontent.com/datawire/kubernaut-standalone/master/etc/calico/calico.yaml

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

# Indicate we are provisioned
printf "%s" "1" > /etc/kubernaut/provisioned

# ----------------------------------------------------------------------------------------------------------------------
# Upload kubeconfig to S3 for download by the user
# ----------------------------------------------------------------------------------------------------------------------
availability_zone=$(ec2-metadata --availability-zone | sed 's/placement: //' | tr -d '\n')

export AWS_DEFAULT_REGION="${availability_zone::-1}"
aws s3api put-object
    --bucket kubernaut-io-v1
    --key instances/${instance_id}/kubeconfig
    --body "$KUBECONFIG_OUTPUT"

# Update io.kubernaut/Registered tag with value of true
aws ec2 create-tags \
    --resources ${instance_id} \
    --tags Key=io.kubernaut/Registered,Value=true

# start the kubernaut-allocator service.
systemctl start kubernaut-allocator

# Indicate we are registered
printf "%s" "1" > /etc/kubernaut/registered
