#!/bin/sh -eux

# https://linuxconfig.org/how-to-install-kubernetes-on-ubuntu-22-04-jammy-jellyfish-linux

echo "Installing Kubernetes"

# Install Dependencies
apt install -y apt-transport-https curl wget

# Install and Configure Docker
apt install -y docker.io
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl daemon-reload
systemctl enable docker
systemctl start docker
systemctl status docker

# Install and Initialize Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
# apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-jammy main"
apt install -y kubeadm kubelet kubectl kubernetes-cni
swapoff -a
sed -i '/swapfile/d' /etc/fstab
hostnamectl set-hostname kubernetes-master # This will have to be different for the worker node image

# Install and Configure containerd
# How to install the Containerd runtime engine on Ubuntu Server 22.04
# https://www.techrepublic.com/article/install-containerd-ubuntu/
wget https://github.com/containerd/containerd/releases/download/v1.6.8/containerd-1.6.8-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.6.8-linux-amd64.tar.gz
wget https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
mkdir /etc/containerd
# Kubeadm unknown service runtime.v1alpha2.RuntimeService
# https://github.com/containerd/containerd/issues/4581#issuecomment-1312083515
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/' /etc/containerd/config.toml
sed -i 's/snapshotter = "overlayfs"/snapshotter = "native"/' /etc/containerd/config.toml
curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd
systemctl status containerd
systemctl restart kubelet
systemctl status kubelet

kubeadm init

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
