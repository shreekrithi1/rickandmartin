#!/usr/bin/bash

# ============================================================
# run-lab.sh  ---  End-to-end runner for lab1/part1
#
# QUICK START (run from ANY directory on the Ubuntu VM):
#   wget -O run-lab.sh https://raw.githubusercontent.com/shreekrithi1/rickandmartin/main/run-lab.sh && chmod +x run-lab.sh && ./run-lab.sh
# ============================================================

set -e

GITHUB_RAW="https://raw.githubusercontent.com/shreekrithi1/rickandmartin/main"
BUNDLE_REPO="https://github.com/shreekrithi1/rickandmartin"
CLONE_DIR="$HOME/rickandmartin-lab"

echo "========================================"
echo " Lab1 Part1 --- End-to-End Setup & Submit"
echo "========================================"

# ----------------------------------------------------------
# 0. Find the correct working directory that has:
#      - provided/capture_submission.sh
#      - 4node-part1.clab.yml
#    If not found locally, clone the bundle repo from GitHub.
# ----------------------------------------------------------
LAB_DIR=""

# Already in the right place?
if [ -f "provided/capture_submission.sh" ] && [ -f "4node-part1.clab.yml" ]; then
    LAB_DIR="$(pwd)"
fi

# Check common Vagrant / home paths
if [ -z "$LAB_DIR" ]; then
    for candidate in \
        "/vagrant/lab1/part1" \
        "$HOME/npp-linux-01-intro-main/lab1/part1" \
        "$HOME/npp-linux-01-intro/lab1/part1" \
        "$HOME/rickandmartin-lab" \
        "$HOME/lab1/part1"
    do
        if [ -f "${candidate}/provided/capture_submission.sh" ]; then
            LAB_DIR="$candidate"
            break
        fi
    done
fi

# Broad filesystem search
if [ -z "$LAB_DIR" ]; then
    echo "[0/5] Searching filesystem for lab files..."
    FOUND=$(find / -maxdepth 8 -name "4node-part1.clab.yml" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        CANDIDATE="$(dirname "$FOUND")"
        if [ -f "${CANDIDATE}/provided/capture_submission.sh" ]; then
            LAB_DIR="$CANDIDATE"
            echo "      Found at: $LAB_DIR"
        fi
    fi
fi

# Last resort: clone the self-contained bundle from GitHub
if [ -z "$LAB_DIR" ]; then
    echo "[0/5] Lab files not found locally. Cloning from GitHub..."
    rm -rf "$CLONE_DIR"
    git clone "$BUNDLE_REPO" "$CLONE_DIR"
    if [ -f "${CLONE_DIR}/provided/capture_submission.sh" ]; then
        LAB_DIR="$CLONE_DIR"
        echo "      Cloned to: $LAB_DIR"
    fi
fi

if [ -z "$LAB_DIR" ]; then
    echo ""
    echo "ERROR: Could not locate or clone the lab files."
    echo "Please open an issue or try manually:"
    echo "  git clone $BUNDLE_REPO ~/mylab && cd ~/mylab && ./run-lab.sh"
    exit 1
fi

cd "$LAB_DIR"
echo "[0/5] Working in: $(pwd)"

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
echo "      do-lab.sh downloaded OK."

# ----------------------------------------------------------
# 3. Make all scripts executable
# ----------------------------------------------------------
echo "[3/5] Setting execute permissions..."
chmod +x do-lab.sh
chmod +x provided/capture_submission.sh
chmod +x provided/change_mac_addrs.sh

# ----------------------------------------------------------
# 4. Clean up any previous submission
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
echo "========================================"

# ----------------------------------------------------------
# Copy submission.tgz to /vagrant so it's accessible on Mac
# ----------------------------------------------------------
if [ -d "/vagrant" ]; then
    echo "[+] Copying submission.tgz to /vagrant/ (Mac shared folder)..."
    cp submission.tgz /vagrant/submission.tgz
    echo "    On your Mac it will be at:"
    echo "    /Users/narendradarla/Downloads/npp-linux-01-intro-main/submission.tgz"
else
    echo "[!] /vagrant not mounted. Manually copy with:"
    echo "    vagrant scp default:$(pwd)/submission.tgz ~/Downloads/"
fi

echo ""
echo "Upload submission.tgz to Coursera to submit."
echo "========================================"
