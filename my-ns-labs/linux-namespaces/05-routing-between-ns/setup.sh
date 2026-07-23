#!/bin/bash

set -e

echo "Starting Lab 05: Routing Between Namespaces..."

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

echo "Bringing up loopback and veth interfaces..."
ip netns exec red ip link set lo up
ip netns exec blue ip link set lo up
ip netns exec red ip link set veth-red up
ip netns exec blue ip link set veth-blue up

echo ""
echo "Routing tables BEFORE adding default routes:"
echo "--- red ---"
ip netns exec red route
echo "--- blue ---"
ip netns exec blue route

echo ""
echo "Adding default routes..."
ip netns exec red ip route add default via 192.168.0.1 dev veth-red
ip netns exec blue ip route add default via 192.168.0.2 dev veth-blue

echo ""
echo "Routing tables AFTER adding default routes:"
echo "--- red ---"
ip netns exec red route
echo "--- blue ---"
ip netns exec blue route

echo ""
echo "Lab 05 Completed Successfully!"
echo "---------------------------------------------------"
echo "Default routes configured."
echo "  red  -> default via 192.168.0.1 dev veth-red"
echo "  blue -> default via 192.168.0.2 dev veth-blue"
echo ""
echo "To clean up: sudo ip netns del red && sudo ip netns del blue"
