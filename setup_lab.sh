#!/bin/bash

# Consolidated Setup Script for Networking Lab
# Derived from "COMPLETE 'FROM SCRATCH' GUIDE"

set -e # Exit on error

echo "--- Phase 2: Preparing Linux Environment ---"

# 1. Update system
sudo apt update

# 2. Resize disk
echo "Checking disk/partition structure..."
lsblk

# Detect LVM or direct partition
if lsblk | grep -q "ubuntu--vg-ubuntu--lv"; then
    echo "Detected LVM (ubuntu-lv). Resizing..."
    sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
elif lsblk | grep -q "sda3"; then
    echo "Detected sda3 partition. Resizing..."
    LANG=en_US.UTF-8 sudo growpart /dev/sda 3
    sudo resize2fs /dev/sda3
else
    echo "Attempting direct resize of /dev/sda..."
    sudo resize2fs /dev/sda || echo "Resize skipped or not needed."
fi

# 3. Install basic tools
sudo apt install -y net-tools git

# 4. Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh --version 24.0.5
fi

# 5. Fix Docker Permissions & Config
sudo usermod -aG docker $(whoami)
sudo gpasswd -a $(whoami) docker
mkdir -p ~/.docker && echo "{}" > ~/.docker/config.json
sudo chown $(whoami):$(whoami) ~/.docker -R

echo "--- Phase 3: Installing Containerlab ---"

if ! command -v containerlab &> /dev/null; then
    echo "Installing Containerlab v0.44.0..."
    wget https://github.com/srl-labs/containerlab/releases/download/v0.44.0/containerlab_0.44.0_linux_amd64.tar.gz
    tar -xzf containerlab_0.44.0_linux_amd64.tar.gz
    sudo mv containerlab /usr/bin/containerlab
    sudo chmod +x /usr/bin/containerlab
fi

# Verify
containerlab version

echo "--- Phase 4: Deploy and Run the Lab ---"

# 1. Get the code (if not already there)
if [ ! -d "npp-linux-02-router" ]; then
    git clone https://github.com/eric-keller/npp-linux-02-router.git
fi
cd npp-linux-02-router/demo1-cli

# 2. Deploy the network
echo "Pulling network-testing image..."
docker pull ekellercu/network-testing:v0.1

echo "Deploying containerlab topology..."
sudo containerlab deploy -t 3lan-mod2.clab.yml

# 3. Start Example 1
echo "Running Example 1 setup..."
chmod +x setup-ip-ex1.sh
./setup-ip-ex1.sh create

echo "--- Setup Complete! ---"
echo "To test connectivity (expected to fail in Ex 1):"
echo "docker exec -it clab-mod2-play-lan1 ping -c 3 10.0.3.2"
