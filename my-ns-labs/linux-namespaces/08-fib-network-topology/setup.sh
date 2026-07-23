#!/bin/bash

set -e

echo "Starting Lab 08: FIB Network Topology..."

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo or as root!"
  exit 1
fi

echo "Cleaning up previous setup (if any)..."
ip netns del ns1 2>/dev/null || true
ip netns del ns2 2>/dev/null || true
ip netns del ns3 2>/dev/null || true
ip netns del ns4 2>/dev/null || true
ip link del br0 2>/dev/null || true
ip link del br1 2>/dev/null || true

echo "Creating namespaces: ns1, ns2, ns3, ns4..."
ip netns add ns1
ip netns add ns2
ip netns add ns3
ip netns add ns4

echo ""
echo "=== Setting up Network 1 (10.0.0.0/24) via br0 ==="
echo ""

echo "Creating bridge br0..."
ip link add br0 type bridge
ip link set br0 up

echo "Connecting ns1 to br0..."
ip link add veth-ns1 type veth peer name veth-ns1-br
ip link set veth-ns1 netns ns1
ip link set veth-ns1-br master br0
ip netns exec ns1 ip addr add 10.0.0.1/24 dev veth-ns1
ip netns exec ns1 ip link set veth-ns1 up
ip link set veth-ns1-br up

echo "Connecting ns2 to br0..."
ip link add veth-ns2 type veth peer name veth-ns2-br
ip link set veth-ns2 netns ns2
ip link set veth-ns2-br master br0
ip netns exec ns2 ip addr add 10.0.0.2/24 dev veth-ns2
ip netns exec ns2 ip link set veth-ns2 up
ip link set veth-ns2-br up

echo "Connecting ns3 to br0..."
ip link add veth-ns3 type veth peer name veth-ns3-br
ip link set veth-ns3 netns ns3
ip link set veth-ns3-br master br0
ip netns exec ns3 ip addr add 10.0.0.3/24 dev veth-ns3
ip netns exec ns3 ip link set veth-ns3 up
ip link set veth-ns3-br up

echo ""
echo "=== Setting up Network 2 (192.168.1.0/24) via br1 ==="
echo ""

echo "Creating bridge br1..."
ip link add br1 type bridge
ip link set br1 up

echo "Connecting ns1 to br1 (ns1 is now a router between both networks)..."
ip link add veth-ns1b type veth peer name veth-ns1b-br
ip link set veth-ns1b netns ns1
ip link set veth-ns1b-br master br1
ip netns exec ns1 ip addr add 192.168.1.1/24 dev veth-ns1b
ip netns exec ns1 ip link set veth-ns1b up
ip link set veth-ns1b-br up

echo "Connecting ns4 to br1..."
ip link add veth-ns4 type veth peer name veth-ns4-br
ip link set veth-ns4 netns ns4
ip link set veth-ns4-br master br1
ip netns exec ns4 ip addr add 192.168.1.2/24 dev veth-ns4
ip netns exec ns4 ip link set veth-ns4 up
ip netns exec ns4 ip link set lo up
ip link set veth-ns4-br up

echo ""
echo "=== Enabling IP Forwarding on ns1 (router) ==="
echo ""

ip netns exec ns1 sysctl -w net.ipv4.ip_forward=1

echo ""
echo "=== Adding route from ns2 to Network 2 ==="
echo ""

ip netns exec ns2 ip route add 192.168.1.0/24 via 10.0.0.1

echo ""
echo "=== FIB / Routing Tables ==="
echo ""

echo "--- ns1 routes (connected to both networks) ---"
ip netns exec ns1 ip route show

echo ""
echo "--- ns2 routes ---"
ip netns exec ns2 ip route show

echo ""
echo "--- ns4 routes ---"
ip netns exec ns4 ip route show

echo ""
echo "=== Testing Cross-Network Connectivity ==="
echo ""

echo "Pinging ns4 (192.168.1.2) from ns2 (10.0.0.2) through ns1..."
ip netns exec ns2 ping -c 3 192.168.1.2

echo ""
echo "Checking route decision for 192.168.1.2 from ns2:"
ip netns exec ns2 ip route get 192.168.1.2

echo ""
echo "Lab 08 Completed Successfully!"
echo "---------------------------------------------------"
echo "Network topology:"
echo "  Network 1 (10.0.0.0/24):  ns1=10.0.0.1, ns2=10.0.0.2, ns3=10.0.0.3"
echo "  Network 2 (192.168.1.0/24): ns1=192.168.1.1, ns4=192.168.1.2"
echo "  ns1 acts as a router between both networks."
echo ""
echo "To clean up: sudo ip link del br0 && sudo ip link del br1 && sudo ip netns del ns1 && sudo ip netns del ns2 && sudo ip netns del ns3 && sudo ip netns del ns4"
