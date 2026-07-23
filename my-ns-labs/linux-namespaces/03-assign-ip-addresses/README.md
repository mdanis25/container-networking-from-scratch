# Lab 03: Assign IP Addresses

## Objective

Give each namespace's interface an IP address so they can actually find and talk to each other.

## Prerequisites

- Completed [Lab 02](../02-connect-network-ns-with-veth/)
- Two namespaces (`red`, `blue`) with a veth pair connected between them

---

## Why Do We Need IPs?

IP addresses are like phone numbers. Without one, nobody can reach you and you cannot reach anybody. The veth cable is plugged in, but without IPs on both ends, no data can flow.

---

## Step 1: Assign IP to Red

```bash
sudo ip netns exec red ip addr add 192.168.0.1/24 dev veth-red
```

![Assign IP Addresses](../../assets/assign-ip-addr.png)

**What this does:** Gives the `veth-red` interface inside the red namespace the IP address `192.168.0.1`. The `/24` means it is on the subnet `192.168.0.0/24`.

**Why we need it:** Without an IP, the kernel has no idea where to send data from this interface. The IP is what makes the interface reachable on the network.

---

## Step 2: Assign IP to Blue

```bash
sudo ip netns exec blue ip addr add 192.168.0.2/24 dev veth-blue
```

**What this does:** Gives the `veth-blue` interface inside the blue namespace the IP address `192.168.0.2`. Same subnet as red.

**Why we need it:** Both ends need to be on the same subnet (`192.168.0.0/24`) so they can talk directly to each other without needing a router.

---

## Step 3: Verify the IPs

Check red:

```bash
sudo ip netns exec red ip addr show
```

**Expected output:**

```
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
6: veth-red@if7: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 22:21:fc:9e:d0:2b brd ff:ff:ff:ff:ff:ff link-netns blue
    inet 192.168.0.1/24 scope global veth-red
       valid_lft forever preferred_lft forever
```

Check blue:

```bash
sudo ip netns exec blue ip addr show
```

**Expected output:**

```
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
7: veth-blue@if6: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 2e:34:8e:0c:1c:6e brd ff:ff:ff:ff:ff:ff link-netns red
    inet 192.168.0.2/24 scope global veth-blue
       valid_lft forever preferred_lft forever
```

**What to look for:** The `inet 192.168.0.x/24` line. If you see that, the IP was assigned correctly. If you do not see it, you probably typed the command wrong or used the wrong interface name.

---

## Step 4: Clean Up

```bash
sudo ip netns del red
sudo ip netns del blue
```

---

## Summary

| What | Command |
|------|---------|
| Assign IP | `sudo ip netns exec <ns> ip addr add <ip>/<cidr> dev <interface>` |
| Verify IP | `sudo ip netns exec <ns> ip addr show` |

---

**Next Lab:** [04 - Bring Interfaces Up](../04-bring-interfaces-up/)
