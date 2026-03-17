#!/usr/bin/bash

# ============================================================
# run-lab.sh  ---  End-to-end runner for lab1/part1
#
# QUICK START on your Ubuntu VM (run from any directory):
#   wget -O run-lab.sh https://raw.githubusercontent.com/shreekrithi1/rickandmartin/main/run-lab.sh && chmod +x run-lab.sh && ./run-lab.sh
# ============================================================

set -e

GITHUB_RAW="https://raw.githubusercontent.com/shreekrithi1/rickandmartin/main"
COURSE_REPO="https://github.com/ucar-cs/npp-linux-01-intro"   # fallback clone

echo "========================================"
echo " Lab1 Part1 --- End-to-End Setup & Submit"
echo "========================================"

# ----------------------------------------------------------
# 0. Find the lab1/part1 directory.
#    Checks fixed paths first, then does a broad find,
#    and finally clones the repo as a last resort.
# ----------------------------------------------------------
LAB_DIR=""

# Check if we're already in the right place
if [ -f "provided/capture_submission.sh" ] && [ -f "4node-part1.clab.yml" ]; then
    LAB_DIR="$(pwd)"
fi

# Search common fixed paths
if [ -z "$LAB_DIR" ]; then
    for candidate in \
        "/vagrant/lab1/part1" \
        "$HOME/npp-linux-01-intro-main/lab1/part1" \
        "$HOME/npp-linux-01-intro/lab1/part1" \
        "$HOME/lab1/part1"
    do
        if [ -f "${candidate}/provided/capture_submission.sh" ]; then
            LAB_DIR="$candidate"
            break
        fi
    done
fi

# Broad find across home and /vagrant
if [ -z "$LAB_DIR" ]; then
    echo "[0/5] Searching for lab1/part1 on this machine..."
    FOUND=$(find / -maxdepth 8 -name "4node-part1.clab.yml" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        LAB_DIR="$(dirname "$FOUND")"
        echo "      Found at: $LAB_DIR"
    fi
fi

# Last resort: clone the course repo into home dir
if [ -z "$LAB_DIR" ]; then
    echo "[0/5] Repo not found locally. Cloning course repo..."
    git clone https://github.com/erickkeller/npp-linux-01-intro-main "$HOME/npp-linux-01-intro-main" 2>/dev/null \
    || git clone https://github.com/ucar-cs/npp-linux-01-intro "$HOME/npp-linux-01-intro" 2>/dev/null \
    || true

    for candidate in \
        "$HOME/npp-linux-01-intro-main/lab1/part1" \
        "$HOME/npp-linux-01-intro/lab1/part1"
    do
        if [ -f "${candidate}/provided/capture_submission.sh" ]; then
            LAB_DIR="$candidate"
            break
        fi
    done
fi

# Still not found — give clear instructions
if [ -z "$LAB_DIR" ]; then
    echo ""
    echo "ERROR: Could not find or clone the lab repo."
    echo ""
    echo "Please clone the course repo manually, then re-run:"
    echo ""
    echo "  git clone <course-repo-url> ~/npp-linux-01-intro-main"
    echo "  cd ~/npp-linux-01-intro-main/lab1/part1"
    echo "  chmod +x run-lab.sh && ./run-lab.sh"
    echo ""
    exit 1
fi

cd "$LAB_DIR"
echo "[0/5] Working directory: $(pwd)"

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
echo " Upload submission.tgz to Coursera."
echo "========================================"
