#!/usr/bin/bash

# ============================================================
# run-lab.sh  —  End-to-end runner for lab1/part1
#
# QUICK START on your Ubuntu VM — just run this one command:
#   wget -O run-lab.sh https://raw.githubusercontent.com/shreekrithi1/rickandmartin/main/run-lab.sh && chmod +x run-lab.sh && ./run-lab.sh
#
# Run from the lab1/part1 directory (where 4node-part1.clab.yml lives)
# ============================================================

set -e   # stop immediately on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GITHUB_RAW="https://raw.githubusercontent.com/shreekrithi1/rickandmartin/main"

echo "========================================"
echo " Lab1 Part1 — End-to-End Setup & Submit"
echo "========================================"

# ----------------------------------------------------------
# 1. Create required bind-mount directories
# ----------------------------------------------------------
echo "[1/5] Creating bind-mount directories..."
mkdir -p lab-host1 lab-host2 lab-host3 lab-host4 lab-switch

# ----------------------------------------------------------
# 2. Download do-lab.sh from GitHub using wget
# ----------------------------------------------------------
echo "[2/5] Downloading do-lab.sh from GitHub..."
wget -q -O do-lab.sh "${GITHUB_RAW}/do-lab.sh"
echo "      do-lab.sh downloaded successfully."

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
