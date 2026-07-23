# Lab 05: Routing Between Namespaces

## Objective

Set up default routes so each namespace knows where to send traffic.

## Prerequisites

- Completed [Lab 04](../04-bring-interfaces-up/)
- Two namespaces with veth pair, IPs assigned, and interfaces UP

---

## What Is a Route?

A route is a rule that tells the kernel where to send a packet. If you want to talk to IP `192.168.0.2`, the route says go through this interface and this gateway.

Without a route, the kernel drops the packet and gives you a "network unreachable" error. It literally has no idea where to send the data.

---

## Why Do We Need a Default Route?

A default route is a catch-all. It says if you do not have a specific route for this destination, send it here. We need it so each namespace can send traffic to the other side through the veth pair.

---

## Step 1: Set Default Route for Red

```bash
sudo ip netns exec red ip route add default via 192.168.0.1 dev veth-red
```

**What this does:** Tells the red namespace that any traffic that does not have a specific route should go through `192.168.0.1` on the `veth-red` interface.

**Why we need it:** Without this, red can only talk to IPs directly on the same subnet. The default route gives it a fallback path for everything else.

---

## Step 2: Set Default Route for Blue

```bash
sudo ip netns exec blue ip route add default via 192.168.0.2 dev veth-blue
```

**What this does:** Same thing for blue. Any unmatched traffic goes through `192.168.0.2` on `veth-blue`.

---

## Step 3: Check the Routing Tables

Check red:

```bash
sudo ip netns exec red route
```

**Expected output:**

```
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         192.168.0.1     0.0.0.0         UG    0      0        0 veth-red
192.168.0.0     0.0.0.0         255.255.255.0   U     0      0        0 veth-red
```

Check blue:

```bash
sudo ip netns exec blue route
```

**Expected output:**

```
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         192.168.0.2     0.0.0.0         UG    0      0        0 veth-blue
192.168.0.0     0.0.0.0         255.255.255.0   U     0      0        0 veth-blue
```

**How to read this:**

| Column | Meaning |
|--------|---------|
| **Destination** | Where the traffic is going. `default` means anything not listed specifically. |
| **Gateway** | The next hop IP to send traffic to. |
| **Genmask** | The subnet mask. `0.0.0.0` for default means match everything. |
| **Flags** | `U` = up, `G` = gateway. `UG` means it is up and uses a gateway. |
| **Iface** | Which interface to send it out of. |

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
| Add default route | `sudo ip netns exec <ns> ip route add default via <gateway> dev <interface>` |
| View routing table | `sudo ip netns exec <ns> route` |

---

**Next Lab:** [06 - Test Connectivity](../06-test-connectivity/)
