#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

# Variable Declaration

# set hostname explicitly
sudo hostnamectl set-hostname "${VM_NAME}"

# DNS Setting
sudo sed -i "s/^nameserver .*/nameserver ${DNS_SERVERS}/" /etc/resolv.conf

# disable swap
sudo swapoff -a

# keeps the swap off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo yum update -y

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

## Install containerd Runtime

# mirror EKS setup with older AL2 images
sudo yum install -y yum-plugin-versionlock
sudo yum install -y runc-1.2.6-1.amzn2
sudo yum install -y containerd-1.7.27-1.amzn2.0.3
sudo yum versionlock add runc containerd

sudo yum install -y curl ca-certificates cri-tools iproute-tc

sudo systemctl daemon-reload
sudo systemctl enable containerd --now
sudo systemctl start containerd

echo "containerd runtime installed susccessfully"

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION_SHORT}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION_SHORT}/rpm/repodata/repomd.xml.key
#exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
exclude=cri-tools
EOF

sudo yum install -y kubelet kubectl kubeadm jq

sudo systemctl enable kubelet --now

local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF
