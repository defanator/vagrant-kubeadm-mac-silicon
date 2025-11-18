#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

. /etc/os-release

# Variable Declaration

# set hostname explicitly
sudo hostnamectl set-hostname "${VM_NAME}"

# disable systemd-resolved on AL2023
if [ "${VERSION}" = "2023" ]; then
    systemctl disable systemd-resolved
    systemctl stop systemd-resolved
    rm -f /etc/resolv.conf
fi

# DNS Setting
printf "search localdomain\n" >/etc/resolv.conf
for ns in ${DNS_SERVERS}; do
    printf "nameserver %s\n" "${ns}" >>/etc/resolv.conf
done

# disable overwriting resolv.conf from DHCP
sudo mkdir -p /etc/dhcp/dhclient-enter-hooks.d
cat <<EOF | sudo tee /etc/dhcp/dhclient-enter-hooks.d/skip-resolv-conf-update.sh
#!/bin/sh

make_resolv_conf() {
    # skip any manipulations with /etc/resolv.conf
    return
}
EOF
sudo chmod +x /etc/dhcp/dhclient-enter-hooks.d/skip-resolv-conf-update.sh

# disable swap
sudo swapoff -a

# keeps the swap off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo yum update -y
sudo yum install -y jq

# fix routing in case vagrant has created 2 interfaces sharing the same subnet
_IFACES=($(ip --json a s | jq -r '.[] | select(.flags | any(. == "LOOPBACK") | not) | select(.flags | any(. == "POINTOPOINT") | not) | .ifname'))
sudo /sbin/ifup-local "${_IFACES[1]}"

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

if [ "${VERSION}" != "2023" ]; then
    # mirror EKS setup with older AL2 images
    sudo yum install -y yum-plugin-versionlock
    sudo yum install -y runc-1.2.6-1.amzn2
    sudo yum install -y containerd-1.7.27-1.amzn2.0.3
    sudo yum versionlock add runc containerd
    sudo yum install -y curl ca-certificates iproute-tc
else
    sudo yum install -y iptables-nft
    sudo yum install -y runc containerd
    sudo yum install -y curl-minimal ca-certificates iproute-tc
fi

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
EOF

sudo yum install -y kubelet kubectl kubeadm cri-tools

sudo systemctl enable kubelet --now

local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF
