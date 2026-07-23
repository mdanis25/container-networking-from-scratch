#!/bin/bash

set -e

echo "Starting Lab 07: Bridge Network..."

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo or as root!"
  exit 1
fi

echo "Cleaning up previous setup (if any)..."
ip netns del red 2>/dev/null || true
ip netns del blue 2>/dev/null || true
ip netns del green 2>/dev/null || true
ip link del br0 2>/dev/null || true

echo "Creating 'red', 'blue', and 'green' network namespaces..."
ip netns add red
ip netns add blue
ip netns add green

echo "Creating bridge 'br0'..."
ip link add br0 type bridge
ip link set br0 up

echo ""
echo "Setting up 'red' namespace..."
ip link add veth-red type veth peer name veth-red-br
ip link set veth-red netns red
ip link set veth-red-br master br0
ip netns exec red ip addr add 192.168.0.1/24 dev veth-red
ip netns exec red ip link set lo up
ip netns exec red ip link set veth-red up
ip link set veth-red-br up

echo "Setting up 'blue' namespace..."
ip link add veth-blue type veth peer name veth-blue-br
ip link set veth-blue netns blue
ip link set veth-blue-br master br0
ip netns exec blue ip addr add 192.168.0.2/24 dev veth-blue
ip netns exec blue ip link set lo up
ip netns exec blue ip link set veth-blue up
ip link set veth-blue-br up

echo "Setting up 'green' namespace..."
ip link add veth-green type veth peer name veth-green-br
ip link set veth-green netns green
ip link set veth-green-br master br0
ip netns exec green ip addr add 192.168.0.3/24 dev veth-green
ip netns exec green ip link set lo up
ip netns exec green ip link set veth-green up
ip link set veth-green-br up

echo ""
echo "=== Testing Connectivity Through Bridge ==="
echo ""

echo "Pinging from 'red' to 'blue' (192.168.0.2)..."
ip netns exec red ping -c 3 192.168.0.2

echo ""
echo "Pinging from 'red' to 'green' (192.168.0.3)..."
ip netns exec red ping -c 3 192.168.0.3

echo ""
echo "Pinging from 'blue' to 'green' (192.168.0.3)..."
ip netns exec blue ping -c 3 192.168.0.3

echo ""
echo "Bridge interfaces:"
ip link show master br0

echo ""
echo "Lab 07 Completed Successfully!"
echo "---------------------------------------------------"
echo "All three namespaces communicate through bridge 'br0'."
echo "  red   = 192.168.0.1"
echo "  blue  = 192.168.0.2"
echo "  green = 192.168.0.3"
echo ""
echo "To clean up: sudo ip link del br0 && sudo ip netns del red && sudo ip netns del blue && sudo ip netns del green"
