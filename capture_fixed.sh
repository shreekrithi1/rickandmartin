#!/bin/bash
# capture_fixed.sh - Complete Part 1 + Part 2 capture with correct link state
# Run from: ~/npp-linux-02-router/demo2-bgp

set -euo pipefail

lan1="docker exec clab-mod2-bgp-lan1"
rtrB="docker exec clab-mod2-bgp-rtrB"
rtrC="docker exec clab-mod2-bgp-rtrC"

filename="submission.out"

echo "====== STEP 1: Restoring links to original state ======"
docker exec clab-mod2-bgp-rtrB ip link set eth1 up 2>/dev/null || true
docker exec clab-mod2-bgp-rtrC ip link set eth2 up 2>/dev/null || true
echo "Waiting 90s for BGP to reconverge with links UP..."
sleep 90

echo "====== STEP 2: Verifying BGP is Established ======"
docker exec clab-mod2-bgp-rtrB birdc show protocols | grep -E "BGP|Established"
docker exec clab-mod2-bgp-rtrC birdc show protocols | grep -E "BGP|Established"

echo "====== STEP 3: Capturing Part 1 ======"
# Traceroute Part 1
$lan1 traceroute -s 1.1.1.1 4.4.4.4 2>/dev/null | tr -d '\r' > $filename
echo "---" >> $filename
# rtrB routes
$rtrB birdc show route all 2>/dev/null | tr -d '\r' | grep -v "^BIRD" >> $filename
echo "---" >> $filename
# rtrC routes
$rtrC birdc show route all 2>/dev/null | tr -d '\r' | grep -v "^BIRD" >> $filename
echo "---" >> $filename
echo "Part 1 captured."

echo "====== STEP 4: Failing links A-B (rtrB eth1) and C-D (rtrC eth2) ======"
docker exec clab-mod2-bgp-rtrB ip link set eth1 down
docker exec clab-mod2-bgp-rtrC ip link set eth2 down
echo "Waiting 90s for BGP to reconverge with links DOWN..."
sleep 90

echo "====== STEP 5: Capturing Part 2 ======"
# Traceroute Part 2
$lan1 traceroute -s 1.1.1.1 4.4.4.4 2>/dev/null | tr -d '\r' >> $filename
echo "Part 2 captured."

echo ""
echo "====== FINAL submission.out ======"
cat $filename
echo ""
echo "Serve it:"
echo "  python3 -m http.server 9003"
echo "Then on Mac: http://192.168.64.6:9003/submission.out"
