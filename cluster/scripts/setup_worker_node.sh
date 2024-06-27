#!/bin/bash

hostname worker-node-${worker_number}
echo "worker-node-${worker_number}" > /etc/hostname

export PROJECT_ID=${project_id}
export BUCKET_NAME=${bucket_name}
export SERVICE_ACCOUNT_PRIVATE_KEY=$(echo "${service_account_private_key}" | base64 --decode)

# Update and Install dependencies
apt update -y
apt install apt-transport-https ca-certificates curl software-properties-common -y

# Install gcloud
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

apt update -y
apt install google-cloud-sdk -y

# Init GCloud
mkdir /etc/gcloud
echo $SERVICE_ACCOUNT_PRIVATE_KEY > /etc/gcloud/service-account.json
gcloud auth activate-service-account --key-file=/etc/gcloud/service-account.json
gcloud config set project $PROJECT_ID

# Add Docker Repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" -y

# Enable IP Route Table
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Installing Docker
apt update -y
apt-cache policy docker-ce
apt install docker-ce -y

# Addind Kubernetes 1.28 repo
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Turn Off Swap
swapoff -a
sudo sed -i '/swap/d' /etc/fstab
mount -a
ufw disable

# Installing kubeadm, kubelet & kubectl
apt update -y
apt install kubeadm=1.28.1-1.1 kubelet=1.28.1-1.1 kubectl=1.28.1-1.1 -y

# Restart containerd to make kubeadm work
rm /etc/containerd/config.toml

systemctl restart containerd

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Make sure it waits for the master node to be ready
sleep 1.5m

# Join the worker node
gsutil cp gs://$BUCKET_NAME/join_command.sh /tmp/.
chmod +x /tmp/join_command.sh
bash /tmp/join_command.sh