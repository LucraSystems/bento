#!/bin/sh -eux

# https://linuxconfig.org/how-to-install-kubernetes-on-ubuntu-22-04-jammy-jellyfish-linux

echo "Installing Kubernetes"

apt install -y docker.io
systemctl enable docker
systemctl start docker
apt install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
# apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-jammy main"
apt install -y kubeadm kubelet kubectl kubernetes-cni
swapoff -a
# I'm think swap is turned off in the minification script, but I'm not sure yet.
sed -i '/swapfile/d' /etc/fstab
hostnamectl set-hostname kubernetes-master # This will have to be different for the worker node image
kubeadm init
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
