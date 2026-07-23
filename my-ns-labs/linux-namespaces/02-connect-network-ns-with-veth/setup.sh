#!/bin/bash

set -e

echo "Starting Lab 02: Connect NS with veth..."

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

echo ""
echo "Interfaces BEFORE moving into namespaces:"
ip link show veth-red
ip link show veth-blue

echo ""
echo "Moving veth-red into 'red' namespace..."
ip link set veth-red netns red

echo "Moving veth-blue into 'blue' namespace..."
ip link set veth-blue netns blue

echo ""
echo "Interfaces inside 'red' namespace:"
ip netns exec red ip link show

echo ""
echo "Interfaces inside 'blue' namespace:"
ip netns exec blue ip link show

echo ""
echo "Lab 02 Completed Successfully!"
echo "---------------------------------------------------"
echo "veth pair created and plugged into both namespaces."
echo "Notice 'link-netns red' and 'link-netns blue' in the output."
echo ""
echo "To clean up: sudo ip netns del red && sudo ip netns del blue"
