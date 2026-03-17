#!/bin/bash
# Lab 1 / Part 2 — Fail links and capture final submission
# Run AFTER lab1_part1.sh has completed successfully

echo "====== PART 2: Failing Links A-B and C-D ======"

rtrB="docker exec clab-mod2-bgp-rtrB"
rtrC="docker exec clab-mod2-bgp-rtrC"

$rtrB ip link set eth1 down
$rtrC ip link set eth2 down

echo "Links brought down. Waiting 60s for BGP to reconverge..."
sleep 60

echo "====== Capturing Part 2 Submission ======"
cd ~/npp-linux-02-router/lab1/part1
./capture_submission.sh part2

echo ""
echo "====== DONE! Verify your submission: ======"
cat ~/npp-linux-02-router/lab1/part1/submission.out
