# Lucra Bento Fork

Most of the modifications have been made to the tool chain to build Ubuntu 22.04 LTS Server.
Bento utilizes Packer to generate images.
It is included in this repository as a forked submodule because we want to retain the ability to track upstream changes should there be security or other improvements.

**Note**: Because Bento is a forked repository, it must remain public. Do not store IP in Bento.

```bash
# Setup from new
git submodule init && git submodule update

# Update
git submodule update
```

## Remote Cluster Build

2023-01-16T15:34:26-07:00
I broke it apart because I needed to be sure that NAT would work.
It works fine for installation.
**ToDo**: Bridged network instead of NAT for production.

```bash
# Build Master and Worker 1 with script
./build.sh -c 1 -w 1

# Install Remote Single Master 1
export name="kubernetes_master_001";
sudo virt-install \
  --connect qemu:///system \
  --name $name \
  --network network=default \
  --disk path=/home/ansible/builds/packer-$name/ubuntu-22.04-amd64,device=disk,bus=virtio,format=qcow2 \
  --ram 8192 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --sound none \
  --rng /dev/urandom \
  --virt-type kvm \
  --import \
  --wait 0

# Install Remote Single Worker 1
export name="kubernetes_worker_001";
sudo virt-install \
  --connect qemu:///system \
  --name $name \
  --network network=default \
  --disk path=/home/ansible/builds/packer-$name/ubuntu-22.04-amd64,device=disk,bus=virtio,format=qcow2 \
  --ram 8192 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --sound none \
  --rng /dev/urandom \
  --virt-type kvm \
  --import \
  --wait 0

# Build Remote Single Worker 2
export name="kubernetes_worker_002";
PACKER_LOG=1 packer build \
  -only=qemu \
  -var "name=$name" \
  -var "hostname=$name" \
  bento/packer_templates/ubuntu/ubuntu-22.04-amd64.json

# Build Remote Single Worker 3
export name="kubernetes_worker_003";
PACKER_LOG=1 packer build \
  -only=qemu \
  -var "name=$name" \
  -var "hostname=$name" \
  bento/packer_templates/ubuntu/ubuntu-22.04-amd64.json

# Build Remote Single Worker 4
export name="kubernetes_worker_004";
PACKER_LOG=1 packer build \
  -only=qemu \
  -var "name=$name" \
  -var "hostname=$name" \
  bento/packer_templates/ubuntu/ubuntu-22.04-amd64.json

# Install Remote Single Worker 2
export name="kubernetes_worker_002";
sudo virt-install \
  --connect qemu:///system \
  --name $name \
  --network network=default \
  --disk path=/home/ansible/builds/packer-$name/ubuntu-22.04-amd64,device=disk,bus=virtio,format=qcow2 \
  --ram 8192 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --sound none \
  --rng /dev/urandom \
  --virt-type kvm \
  --import \
  --wait 0

# Install Remote Single Worker 3
export name="kubernetes_worker_003";
sudo virt-install \
  --connect qemu:///system \
  --name $name \
  --network network=default \
  --disk path=/home/ansible/builds/packer-$name/ubuntu-22.04-amd64,device=disk,bus=virtio,format=qcow2 \
  --ram 8192 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --sound none \
  --rng /dev/urandom \
  --virt-type kvm \
  --import \
  --wait 0

# Install Remote Single Worker 4
export name="kubernetes_worker_004";
sudo virt-install \
  --connect qemu:///system \
  --name $name \
  --network network=default \
  --disk path=/home/ansible/builds/packer-$name/ubuntu-22.04-amd64,device=disk,bus=virtio,format=qcow2 \
  --ram 8192 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --sound none \
  --rng /dev/urandom \
  --virt-type kvm \
  --import \
  --wait 0
```

## Local Cluster Build

I started this experiment by building a cluster in the house.
These instructions pertain to that specific setup but inform the remote cluster setup.

### Host Boot

You will want a bridge network configuration on the Host Machine.

```bash
# Configure the Bridge Network
sudo ip link add br0 type bridge
sudo ip address add dev br0 192.168.1.199/24
sudo ip link set enp11s0 master br0
sudo ip link show master br0
sudo ip link set br0 up
```

**Note**: Bridged networking **REQUIRES** two physical NICs.
You can terminate your network connection if you use the active network connection for the bridge network master connection.

### Build Virtual Machines

```bash
# This will use the build script to build several VMs for the environment.
./build.sh -c 2 -w 4
```

### Install Virtual Machines

```bash
# Note that these loops are configured for the sample ranges above.
# Adjust as necessary.
for i in {1..2}
do
  sudo virt-install \
    --connect qemu:///system \
    --name kubernetes_master_`printf "%03d" $i` \
    --network network=bridged-network \
    --disk path=/home/drone/workspace/infrastructure/builds/packer-kubernetes_master_`printf "%03d" $i`/ubuntu-22.04-amd64,device=disk,bus=virtio,format=qcow2 \
    --ram 4096 \
    --vcpus 2 \
    --os-variant ubuntu22.04 \
    --sound none \
    --rng /dev/urandom \
    --virt-type kvm \
    --import \
    --wait 0
done

for i in {1..6}
do
  sudo virt-install \
    --connect qemu:///system \
    --name kubernetes_worker_`printf "%03d" $i` \
    --network network=default \
    --disk path=/home/ansible/builds/packer-kubernetes_worker_`printf "%03d" $i`/ubuntu-22.04-amd64,device=disk,bus=virtio,format=qcow2 \
    --ram 8192 \
    --vcpus 2 \
    --os-variant ubuntu22.04 \
    --sound none \
    --rng /dev/urandom \
    --virt-type kvm \
    --import \
    --wait 0
done
```
