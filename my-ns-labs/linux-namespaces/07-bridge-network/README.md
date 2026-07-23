# Lab 07: Bridge Network

## Objective

Connect multiple namespaces to a single network using a Linux bridge.

## Prerequisites

- Completed [Lab 06](../06-test-connectivity/)
- Understanding of veth pairs and namespaces

---

## What Is a Bridge?

A bridge is like a virtual network switch. It connects multiple network interfaces together so they can all talk to each other. If you have 3 namespaces and you want all of them to communicate, you do not create veth pairs between every pair of them. Instead, you connect each one to a bridge and the bridge handles the rest.

Think of it like a common lounge in the palace. Every child plugs their thread into the lounge switchboard and the switchboard routes messages to the right person.

---

## Why Do We Need a Bridge?

Without a bridge, if you have 3 namespaces and want all of them to talk to each other, you would need 3 separate veth pairs (one between each pair). That gets messy fast. A bridge makes it clean — each namespace gets one veth pair connected to the bridge, and the bridge takes care of forwarding.

This is exactly how Docker sets up networking. When you run multiple containers on the same Docker network, they all connect to a Docker bridge and communicate through it.

---

## Step 1: Create Namespaces

```bash
sudo ip netns add red
sudo ip netns add blue
sudo ip netns add green
```

---

## Step 2: Create the Bridge

```bash
sudo ip link add br0 type bridge
sudo ip link set br0 up
```

**What this does:** Creates a Linux bridge called `br0` and turns it on. Think of it as plugging in a network switch.

**Why we need it:** This is the central point where all namespaces will connect.

---

## Step 3: Create veth Pairs and Connect to Bridge

For red:

```bash
sudo ip link add veth-red type veth peer name veth-red-br
sudo ip link set veth-red netns red
sudo ip link set veth-red-br master br0
```

For blue:

```bash
sudo ip link add veth-blue type veth peer name veth-blue-br
sudo ip link set veth-blue netns blue
sudo ip link set veth-blue-br master br0
```

For green:

```bash
sudo ip link add veth-green type veth peer name veth-green-br
sudo ip link set veth-green netns green
sudo ip link set veth-green-br master br0
```

**What this does:** For each namespace, creates a veth pair, moves one end into the namespace, and connects the other end to the bridge.

**Why we need it:** The end inside the namespace is for that namespace to use. The end on the bridge is what connects it to the common network.

---

## Step 4: Assign IPs

```bash
sudo ip netns exec red ip addr add 192.168.0.1/24 dev veth-red
sudo ip netns exec blue ip addr add 192.168.0.2/24 dev veth-blue
sudo ip netns exec green ip addr add 192.168.0.3/24 dev veth-green
```

---

## Step 5: Bring Everything Up

```bash
sudo ip netns exec red ip link set veth-red up
sudo ip netns exec red ip link set lo up

sudo ip netns exec blue ip link set veth-blue up
sudo ip netns exec blue ip link set lo up

sudo ip netns exec green ip link set veth-green up
sudo ip netns exec green ip link set lo up
```

Also bring up the bridge-side interfaces:

```bash
sudo ip link set veth-red-br up
sudo ip link set veth-blue-br up
sudo ip link set veth-green-br up
```

---

## Step 6: Test Connectivity

Ping from red to blue:

```bash
sudo ip netns exec red ping -c 3 192.168.0.2
```

**Expected output:**

```
PING 192.168.0.2 (192.168.0.2) 56(84) bytes of data.
64 bytes from 192.168.0.2: icmp_seq=1 ttl=64 time=0.045 ms
64 bytes from 192.168.0.2: icmp_seq=2 ttl=64 time=0.067 ms
64 bytes from 192.168.0.2: icmp_seq=3 ttl=64 time=0.061 ms

--- 192.168.0.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.045/0.058/0.067/0.009 ms
```

Ping from red to green:

```bash
sudo ip netns exec red ping -c 3 192.168.0.3
```

**Expected output:**

```
PING 192.168.0.3 (192.168.0.3) 56(84) bytes of data.
64 bytes from 192.168.0.3: icmp_seq=1 ttl=64 time=0.038 ms
64 bytes from 192.168.0.3: icmp_seq=2 ttl=64 time=0.071 ms
64 bytes from 192.168.0.3: icmp_seq=3 ttl=64 time=0.065 ms

--- 192.168.0.3 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.038/0.058/0.071/0.014 ms
```

All three namespaces can talk to each other through the bridge. You only needed one connection per namespace instead of veth pairs between every combination.

---

## Step 7: Clean Up

```bash
sudo ip link del br0
sudo ip netns del red
sudo ip netns del blue
sudo ip netns del green
```

---

## Summary

| What | Command |
|------|---------|
| Create bridge | `sudo ip link add <name> type bridge` |
| Bring bridge up | `sudo ip link set <name> up` |
| Connect veth to bridge | `sudo ip link set <interface> master <bridge>` |

---

**Next Lab:** [08 - FIB Network Topology](../08-fib-network-topology/)
