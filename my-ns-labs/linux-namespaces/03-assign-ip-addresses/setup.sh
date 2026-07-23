#!/bin/bash

set -e

echo "Starting Lab 03: Assign IP Addresses..."

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo or as root!"
  exit 1
fi

echo "Cleaning up previous setup (if any)..."
ip netns del red 2>/dev/null || true
ip netns del blue 2>/dev/null || true

echo "Creating 'red' and 'blue' network namespaces..."
ip netns add red
ip netns add blue

echo "Creating veth pair (veth-red <--> veth-blue)..."
ip link add veth-red type veth peer name veth-blue

echo "Moving interfaces into namespaces..."
ip link set veth-red netns red
ip link set veth-blue netns blue

echo ""
echo "Assigning IP addresses..."
echo "  red  -> 192.168.0.1/24 on veth-red"
echo "  blue -> 192.168.0.2/24 on veth-blue"
ip netns exec red ip addr add 192.168.0.1/24 dev veth-red
ip netns exec blue ip addr add 192.168.0.2/24 dev veth-blue

echo ""
echo "IP addresses inside 'red' namespace:"
ip netns exec red ip addr show

echo ""
echo "IP addresses inside 'blue' namespace:"
ip netns exec blue ip addr show

echo ""
echo "Lab 03 Completed Successfully!"
echo "---------------------------------------------------"
echo "IPs assigned: red=192.168.0.1  blue=192.168.0.2"
echo "Interfaces are still DOWN. Ping will NOT work yet."
echo ""
echo "To clean up: sudo ip netns del red && sudo ip netns del blue"
