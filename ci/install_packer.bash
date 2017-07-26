#!/usr/bin/env bash
set -euxo pipefail

TOOLS_DIR=${TOOLS_DIR:?"ERROR: TOOLS_DIR not set"}
PACKER_VERSION=${PACKER_VERSION:?"ERROR: PACKER_VERSION not set"}
PACKER_SHA256SUM=${PACKER_SHA256SUM:?"ERROR: PACKER_SHA256SUM not set"}

curl -L --output /tmp/packer-${PACKER_VERSION}.zip \
     https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip

echo "${PACKER_SHA256SUM}  /tmp/packer-${PACKER_VERSION}.zip" > /tmp/packer_SHA256
sha256sum -c /tmp/packer_SHA256

unzip /tmp/packer-${PACKER_VERSION}.zip
mv packer ${TOOLS_DIR}/packer
chmod +x ${TOOLS_DIR}/packer

packer version
