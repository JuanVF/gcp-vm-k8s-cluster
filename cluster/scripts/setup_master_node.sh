#!/bin/bash

hostname master-node
echo "master-node" > /etc/hostname

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

# Here we are going to use the Public IP to expose the network
export cidrrange="192.168.0.0/16"
export pubip=`curl -s http://checkip.amazonaws.com`

# Restart containerd to make kubeadm work
rm /etc/containerd/config.toml

systemctl restart containerd

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Start Kubeadm
kubeadm init --apiserver-advertise-address=10.10.10.2 --pod-network-cidr=$cidrrange --apiserver-cert-extra-sans=$pubip > /tmp/result.out

sleep 1m

cat /tmp/result.out

# Copy the join command for the worker nodes to a bucket
tail -2 /tmp/result.out > /tmp/join_command.sh;
gsutil cp /tmp/join_command.sh gs://$BUCKET_NAME;

mkdir -p /root/.kube;

# Kubeconfig for root
cp -i /etc/kubernetes/admin.conf /root/.kube/config
cp -i /etc/kubernetes/admin.conf /tmp/admin.conf

# Kubeconfig for VM User
mkdir -p /home/ubuntu/.kube;
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config;
chmod 755 /home/ubuntu/.kube/config

export KUBECONFIG=/root/.kube/config

# Installing Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
bash get_helm.sh

# Setup Flannel
kubectl create --kubeconfig $KUBECONFIG ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged

helm repo add flannel https://flannel-io.github.io/flannel/
helm install flannel --set podCidr="$cidrrange" --namespace kube-flannel flannel/flannel