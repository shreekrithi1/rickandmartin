#!/bin/bash
# Fixed capture script - removes -it flag to prevent TTY carriage-return corruption

# Use docker exec WITHOUT -it to avoid \r in output
lan1="docker exec clab-mod2-bgp-lan1"
rtrB="docker exec clab-mod2-bgp-rtrB"
rtrC="docker exec clab-mod2-bgp-rtrC"

filename="submission.out"

echo "Regenerating submission.out with clean formatting..."

# Part 1: traceroute + rtrB routes + rtrC routes
$lan1 traceroute -s 1.1.1.1 4.4.4.4 2>/dev/null | tr -d '\r' > $filename
echo "---" >> $filename
$rtrB birdc show route all 2>/dev/null | tr -d '\r' >> $filename
echo "---" >> $filename
$rtrC birdc show route all 2>/dev/null | tr -d '\r' >> $filename
echo "---" >> $filename

# Part 2: fail links, wait, then final traceroute
echo "Failing links A-B and C-D..."
docker exec clab-mod2-bgp-rtrB ip link set eth1 down
docker exec clab-mod2-bgp-rtrC ip link set eth2 down
echo "Waiting 60s for BGP reconvergence..."
sleep 60
$lan1 traceroute -s 1.1.1.1 4.4.4.4 2>/dev/null | tr -d '\r' >> $filename

echo ""
echo "====== submission.out is ready ======"
cat $filename
