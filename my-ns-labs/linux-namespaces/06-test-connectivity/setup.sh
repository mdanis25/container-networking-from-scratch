#!/bin/bash

set -e

echo "Starting Lab 06: Test Connectivity..."

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

echo "Adding default routes..."
ip netns exec red ip route add default via 192.168.0.1 dev veth-red
ip netns exec blue ip route add default via 192.168.0.2 dev veth-blue

echo ""
echo "=== Testing Connectivity ==="
echo ""

echo "Pinging from 'red' to 'blue' (192.168.0.2)..."
ip netns exec red ping -c 3 192.168.0.2

echo ""
echo "Pinging from 'blue' to 'red' (192.168.0.1)..."
ip netns exec blue ping -c 3 192.168.0.1

echo ""
echo "=== Checking ARP Cache ==="
echo ""

echo "ARP table for 'red':"
ip netns exec red arp

echo ""
echo "ARP table for 'blue':"
ip netns exec blue arp

echo ""
echo "Lab 06 Completed Successfully!"
echo "---------------------------------------------------"
echo "Both namespaces can reach each other."
echo "ARP tables show learned MAC addresses."
echo ""
echo "To clean up: sudo ip netns del red && sudo ip netns del blue"
