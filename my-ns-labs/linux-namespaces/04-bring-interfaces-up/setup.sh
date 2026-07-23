#!/bin/bash

set -e

echo "Starting Lab 04: Bring Interfaces Up..."

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

echo "Assigning IP addresses..."
ip netns exec red ip addr add 192.168.0.1/24 dev veth-red
ip netns exec blue ip addr add 192.168.0.2/24 dev veth-blue

echo ""
echo "Interfaces BEFORE bringing them up:"
echo "--- red ---"
ip netns exec red ip link show veth-red
echo "--- blue ---"
ip netns exec blue ip link show veth-blue

echo ""
echo "Bringing up loopback interfaces..."
ip netns exec red ip link set lo up
ip netns exec blue ip link set lo up

echo "Bringing up veth interfaces..."
ip netns exec red ip link set veth-red up
ip netns exec blue ip link set veth-blue up

echo ""
echo "Interfaces AFTER bringing them up:"
echo "--- red ---"
ip netns exec red ip link show veth-red
echo "--- blue ---"
ip netns exec blue ip link show veth-blue

echo ""
echo "Lab 04 Completed Successfully!"
echo "---------------------------------------------------"
echo "Both interfaces are now UP."
echo "Notice 'UP,LOWER_UP' in the output."
echo ""
echo "To clean up: sudo ip netns del red && sudo ip netns del blue"
