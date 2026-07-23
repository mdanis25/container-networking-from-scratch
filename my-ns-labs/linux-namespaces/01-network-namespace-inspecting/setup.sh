#!/bin/bash

set -e

echo "Starting Lab 01: Network Namespace Inspecting..."

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

echo "Listing all network namespaces..."
ip netns list

echo ""
echo "Inspecting 'red' namespace interfaces..."
ip netns exec red ip link show

echo ""
echo "Inspecting 'blue' namespace interfaces..."
ip netns exec blue ip link show

echo ""
echo "Pinging loopback inside 'red'..."
ip netns exec red ping -c 2 127.0.0.1

echo ""
echo "Pinging loopback inside 'blue'..."
ip netns exec blue ping -c 2 127.0.0.1

echo ""
echo "Lab 01 Completed Successfully!"
echo "---------------------------------------------------"
echo "Namespaces 'red' and 'blue' are created and isolated."
echo "Each only sees its own loopback interface."
echo ""
echo "To clean up: sudo ip netns del red && sudo ip netns del blue"
