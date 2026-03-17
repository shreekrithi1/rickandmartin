#!/usr/bin/bash

# ============================================================
# run-lab.sh  —  End-to-end runner for lab1/part1
# Run from the lab1/part1 directory:
#   chmod +x run-lab.sh && ./run-lab.sh
# ============================================================

set -e   # stop immediately on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo " Lab1 Part1 — End-to-End Setup & Submit"
echo "========================================"

# ----------------------------------------------------------
# 1. Create required bind-mount directories
# ----------------------------------------------------------
echo "[1/5] Creating bind-mount directories..."
mkdir -p lab-host1 lab-host2 lab-host3 lab-host4 lab-switch

# ----------------------------------------------------------
# 2. Write the lab solution into do-lab.sh
# ----------------------------------------------------------
echo "[2/5] Writing bridge solution to do-lab.sh..."
cat > do-lab.sh << 'EOF'
#!/usr/bin/bash

# INCLUDE ALL COMMANDS NEEDED TO PERFORM THE LAB
# This file will get called from capture_submission.sh

# Create a Linux bridge on the switch node
docker exec clab-lab1-part1-switch ip link add name mybridge type bridge

# Bring the bridge interface up
docker exec clab-lab1-part1-switch ip link set mybridge up

# Add all 4 host-facing interfaces as bridge members
docker exec clab-lab1-part1-switch ip link set eth1 master mybridge
docker exec clab-lab1-part1-switch ip link set eth2 master mybridge
docker exec clab-lab1-part1-switch ip link set eth3 master mybridge
docker exec clab-lab1-part1-switch ip link set eth4 master mybridge
EOF

# ----------------------------------------------------------
# 3. Make all scripts executable
# ----------------------------------------------------------
echo "[3/5] Setting execute permissions..."
chmod +x do-lab.sh
chmod +x provided/capture_submission.sh
chmod +x provided/change_mac_addrs.sh

# ----------------------------------------------------------
# 4. Clean up any previous submission so script can re-run
# ----------------------------------------------------------
echo "[4/5] Cleaning up any previous submission..."
rm -rf submission submission.tgz
# Also clean any leftover pcap files from previous runs
rm -f lab-host1/*.pcap lab-host2/*.pcap lab-host3/*.pcap lab-host4/*.pcap 2>/dev/null || true

# ----------------------------------------------------------
# 5. Run the official submission capture script
# ----------------------------------------------------------
echo "[5/5] Running capture_submission.sh..."
./provided/capture_submission.sh

echo ""
echo "========================================"
echo " Done!  submission.tgz is ready."
echo " Upload it to Coursera to submit."
echo "========================================"
