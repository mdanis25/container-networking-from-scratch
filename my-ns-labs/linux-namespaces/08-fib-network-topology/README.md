# Lab 08: FIB Network Topology

## Objective

Understand the Forwarding Information Base (FIB) and how Linux makes routing decisions across multiple namespaces and networks.

## Prerequisites

- Completed [Lab 07](../07-bridge-network/)
- Understanding of bridges, routes, and namespaces

---

## What Is the FIB?

The FIB stands for Forwarding Information Base. It is basically the kernel's lookup table for routing decisions. When a packet arrives, the kernel looks at the destination IP and checks the FIB to figure out where to send it next.

You already used the FIB in earlier labs when you set up routes. Every route you added went into the FIB. The `route` and `ip route` commands show you what is in there.

---

## Why Does This Matter?

In a simple two-namespace setup, routing is easy — there is only one path. But when you have multiple namespaces, bridges, and connections to the outside world, the kernel needs to make smart decisions about where to forward each packet. That is what the FIB does.

Understanding the FIB helps you debug complex network setups. If traffic is going the wrong way or getting dropped, checking the FIB tells you exactly what the kernel thinks should happen to each packet.

---

## Step 1: Set Up a Multi-Namespace Lab

Create three namespaces and a bridge (same as Lab 07):

```bash
sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add ns3

sudo ip link add br0 type bridge
sudo ip link set br0 up

sudo ip link add veth-ns1 type veth peer name veth-ns1-br
sudo ip link set veth-ns1 netns ns1
sudo ip link set veth-ns1-br master br0

sudo ip link add veth-ns2 type veth peer name veth-ns2-br
sudo ip link set veth-ns2 netns ns2
sudo ip link set veth-ns2-br master br0

sudo ip link add veth-ns3 type veth peer name veth-ns3-br
sudo ip link set veth-ns3 netns ns3
sudo ip link set veth-ns3-br master br0

sudo ip netns exec ns1 ip addr add 10.0.0.1/24 dev veth-ns1
sudo ip netns exec ns2 ip addr add 10.0.0.2/24 dev veth-ns2
sudo ip netns exec ns3 ip addr add 10.0.0.3/24 dev veth-ns3

sudo ip netns exec ns1 ip link set veth-ns1 up
sudo ip netns exec ns1 ip link set lo up
sudo ip netns exec ns2 ip link set veth-ns2 up
sudo ip netns exec ns2 ip link set lo up
sudo ip netns exec ns3 ip link set veth-ns3 up
sudo ip netns exec ns3 ip link set lo up

sudo ip link set veth-ns1-br up
sudo ip link set veth-ns2-br up
sudo ip link set veth-ns3-br up
```

---

## Step 2: Look at the FIB Using ip route

```bash
sudo ip netns exec ns1 ip route show
```

**Expected output:**

```
10.0.0.0/24 dev veth-ns1 proto kernel scope link src 10.0.0.1
```

**What this tells you:** The kernel in ns1 knows that the `10.0.0.0/24` network is reachable directly through `veth-ns1`. No gateway needed because both sides are on the same subnet.

---

## Step 3: Add a Second Network

Now let us create a second bridge with two more namespaces on a different subnet:

```bash
sudo ip link add br1 type bridge
sudo ip link set br1 up

sudo ip netns add ns4
sudo ip link add veth-ns4 type veth peer name veth-ns4-br
sudo ip link set veth-ns4 netns ns4
sudo ip link set veth-ns4-br master br1

sudo ip link add veth-ns1b type veth peer name veth-ns1b-br
sudo ip link set veth-ns1b netns ns1
sudo ip link set veth-ns1b-br master br1

sudo ip netns exec ns1 ip addr add 192.168.1.1/24 dev veth-ns1b
sudo ip netns exec ns4 ip addr add 192.168.1.2/24 dev veth-ns4

sudo ip netns exec ns1 ip link set veth-ns1b up
sudo ip netns exec ns4 ip link set veth-ns4 up
sudo ip netns exec ns4 ip link set lo up

sudo ip link set veth-ns1b-br up
sudo ip link set veth-ns4-br up
```

Now `ns1` is connected to both networks — `10.0.0.0/24` (via br0) and `192.168.1.0/24` (via br1). It acts like a router between the two.

---

## Step 4: Check ns1's FIB

```bash
sudo ip netns exec ns1 ip route show
```

**Expected output:**

```
10.0.0.0/24 dev veth-ns1 proto kernel scope link src 10.0.0.1
192.168.1.0/24 dev veth-ns1b proto kernel scope link src 192.168.1.1
```

**What this tells you:** ns1 has routes to both subnets. The kernel knows that `10.0.0.0/24` traffic goes out `veth-ns1` and `192.168.1.0/24` traffic goes out `veth-ns1b`.

---

## Step 5: Add a Route from ns2 to ns4's Network

ns2 does not know about `192.168.1.0/24`. We need to tell it to send that traffic through ns1:

```bash
sudo ip netns exec ns2 ip route add 192.168.1.0/24 via 10.0.0.1
```

**What this does:** Tells ns2 that if it wants to reach `192.168.1.0/24`, send the traffic to `10.0.0.1` (which is ns1). ns1 will then forward it to the right place.

**Why we need it:** ns2 only knows about `10.0.0.0/24`. Without this route, any traffic from ns2 to ns4 would be dropped.

---

## Step 6: Enable IP Forwarding on ns1

For ns1 to act as a router, it needs IP forwarding enabled:

```bash
sudo ip netns exec ns1 sysctl -w net.ipv4.ip_forward=1
```

**What this does:** Tells the kernel in ns1 to forward packets between its interfaces instead of dropping them.

**Why we need it:** By default, Linux does not forward packets between interfaces. It only processes packets meant for itself. Enabling this turns ns1 into a router.

---

## Step 7: Test Cross-Network Connectivity

Ping from ns2 to ns4 through ns1:

```bash
sudo ip netns exec ns2 ping -c 3 192.168.1.2
```

**Expected output:**

```
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=63 time=0.058 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=63 time=0.073 ms
64 bytes from 192.168.1.2: icmp_seq=3 ttl=63 time=0.069 ms

--- 192.168.1.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.058/0.067/0.073/0.006 ms
```

Notice `ttl=63` instead of `ttl=64`. That means the packet went through one router (ns1) before reaching the destination. Each hop decrements the TTL by one.

---

## Step 8: Inspect the Full FIB

You can also use `ip route get` to see what route the kernel would choose for a specific destination:

```bash
sudo ip netns exec ns2 ip route get 192.168.1.2
```

**Expected output:**

```
192.168.1.2 via 10.0.0.1 dev veth-ns2 src 10.0.0.2 uid 0
    cache
```

**What this tells you:** When ns2 wants to reach `192.168.1.2`, the kernel says go through `10.0.0.1` (ns1) via the `veth-ns2` interface. This is the FIB in action — it looked up the destination, found the matching route, and decided the path.

---

## Step 9: Clean Up

```bash
sudo ip link del br0
sudo ip link del br1
sudo ip netns del ns1
sudo ip netns del ns2
sudo ip netns del ns3
sudo ip netns del ns4
```

---

## Summary

| What | Command |
|------|---------|
| Show FIB / routes | `ip route show` or `ip netns exec <ns> ip route show` |
| Add route | `ip route add <dest> via <gateway>` |
| Check route for specific IP | `ip route get <ip>` |
| Enable IP forwarding | `sysctl -w net.ipv4.ip_forward=1` |

---

**Back to Main:** [README](../README.md)
