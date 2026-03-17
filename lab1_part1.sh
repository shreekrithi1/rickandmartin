#!/bin/bash
# Lab 1 / Part 1 — Complete automated setup
# Run inside your Ubuntu VM: bash lab1_part1.sh

set -e
resize_or_skip() { "$@" || echo "(skipped: already done)"; }

echo "====== PHASE 1: Installing Tools ======"

# Fix dpkg/debconf lock (Ubuntu's auto-updater runs in background)
echo "Stopping background update services..."
sudo systemctl stop unattended-upgrades apt-daily.service apt-daily-upgrade.service 2>/dev/null || true
sudo systemctl disable unattended-upgrades 2>/dev/null || true
sudo killall apt apt-get dpkg unattended-upgrade 2>/dev/null || true
sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
sudo rm -f /var/cache/debconf/config.dat-old
sudo dpkg --configure -a 2>/dev/null || true
export DEBIAN_FRONTEND=noninteractive
sleep 3

sudo apt update -y
sudo apt install -y git curl wget

# Docker
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
fi
sudo usermod -aG docker $USER
mkdir -p ~/.docker && echo "{}" > ~/.docker/config.json
sudo chown $USER:$USER ~/.docker -R

# Switch Docker to 'vfs' storage driver (required for emulated x86 VMs)
# overlay2 fails with "operation not supported" on this filesystem
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "storage-driver": "vfs"
}
EOF
sudo systemctl restart docker
echo "Docker configured with vfs storage driver"


# Containerlab
if ! command -v containerlab &>/dev/null; then
    wget -q https://github.com/srl-labs/containerlab/releases/download/v0.44.0/containerlab_0.44.0_linux_amd64.tar.gz
    tar -xzf containerlab_0.44.0_linux_amd64.tar.gz
    sudo mv containerlab /usr/bin/containerlab
    sudo chmod +x /usr/bin/containerlab
    rm -f containerlab_0.44.0_linux_amd64.tar.gz
fi

echo "====== PHASE 2: Get Lab Code ======"
if [ ! -d "npp-linux-02-router" ]; then
    git clone https://github.com/eric-keller/npp-linux-02-router.git
fi
cd npp-linux-02-router/demo2-bgp

echo "====== PHASE 3: Patch Files for B-C Link ======"

# 3a. Add B-C link to topology file
if ! grep -q "rtrB:eth3" diamond-mod2.clab.yml; then
    echo '    - endpoints: ["rtrB:eth3", "rtrC:eth3"]' >> diamond-mod2.clab.yml
    echo "Added B-C link to diamond-mod2.clab.yml"
fi

# 3b. Add BtoC peering to rtrB-bird.conf
if ! grep -q "BtoC" mod2-bird-confs/rtrB-bird.conf; then
    cat >> mod2-bird-confs/rtrB-bird.conf << 'EOF'

protocol bgp BtoC {
        description "BtoC";
        local as 65001;
        neighbor 10.10.6.1 as 65002;
        ipv4 {
                import filter rt_import;
                export where source ~ [ RTS_STATIC, RTS_BGP ];
        };
}
EOF
    echo "Added BtoC peering to rtrB-bird.conf"
fi

# 3c. Add CtoB peering to rtrC-bird.conf
if ! grep -q "CtoB" mod2-bird-confs/rtrC-bird.conf; then
    cat >> mod2-bird-confs/rtrC-bird.conf << 'EOF'

protocol bgp CtoB {
        description "CtoB";
        local as 65002;
        neighbor 10.10.6.2 as 65001;
        ipv4 {
                import filter rt_import;
                export where source ~ [ RTS_STATIC, RTS_BGP ];
        };
}
EOF
    echo "Added CtoB peering to rtrC-bird.conf"
fi

# 3d. Add IP addresses for eth3 in setup-ip-diamond.sh
if ! grep -q "10.10.6.2" setup-ip-diamond.sh; then
    sed -i '/\$rtrB ip addr add 10.10.3.1\/30 dev eth2/a \$rtrB ip addr add 10.10.6.2/30 dev eth3' setup-ip-diamond.sh
    sed -i '/\$rtrC ip addr add 10.10.4.1\/30 dev eth2/a \$rtrC ip addr add 10.10.6.1/30 dev eth3' setup-ip-diamond.sh
    echo "Added eth3 IPs to setup-ip-diamond.sh"
fi

echo "====== PHASE 4: Pull Docker Image (this may take 20-30 min) ======"
# Clean up any leftover data from previous failed attempts
echo "Checking disk space..."
df -h /
echo "Cleaning up previous Docker data to free space..."
sudo docker system prune -a -f 2>/dev/null || true
echo "Disk space after cleanup:"
df -h /
sudo docker pull ekellercu/network-testing:v0.1


echo "====== PHASE 5: Deploy Topology ======"
resize_or_skip sudo containerlab destroy -t diamond-mod2.clab.yml
sudo containerlab deploy -t diamond-mod2.clab.yml
sudo ./setup-ip-diamond.sh create
sudo ./start-bird.sh

echo "====== PHASE 6: Waiting 60s for BGP to converge... ======"
sleep 60

echo "====== PHASE 7: Verifying BGP Peering ======"
echo "--- rtrB protocols ---"
sudo docker exec clab-mod2-bgp-rtrB birdc show protocols
echo "--- rtrC protocols ---"
sudo docker exec clab-mod2-bgp-rtrC birdc show protocols

echo "====== PHASE 8: Capturing Part 1 Submission ======"
cd ~/npp-linux-02-router/lab1/part1
sudo bash capture_submission.sh part1

echo ""
echo "====== DONE! Part 1 captured to submission.out ======"
echo "Run 'cat ~/npp-linux-02-router/lab1/part1/submission.out' to verify."
echo ""
echo "Next: do Part 2 (fail links) then run: bash capture_submission.sh part2"
