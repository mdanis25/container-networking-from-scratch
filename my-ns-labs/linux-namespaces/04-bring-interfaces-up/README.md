# Lab 04: Bring Interfaces Up

## Objective

Turn on the interfaces inside both namespaces so data can actually flow through the veth pair.

## Prerequisites

- Completed [Lab 03](../03-assign-ip-addresses/)
- Two namespaces with veth pair and IPs assigned

---

## Why Do We Need to Bring Them Up?

Every new network interface starts in the `DOWN` state. That means the kernel is ignoring it completely. No data goes in, no data comes out. It is like having a phone that is powered off — all the wiring is there but nothing works until you hit the power button.

This is the step most people forget and then wonder why their ping is not working.

---

## Step 1: Bring Up Red's Interface

```bash
sudo ip netns exec red ip link set veth-red up
```

**What this does:** Turns on the `veth-red` interface inside the red namespace.

**Why we need it:** The interface is DOWN by default. We have to tell the kernel to start using it.

---

## Step 2: Bring Up Blue's Interface

```bash
sudo ip netns exec blue ip link set veth-blue up
```

**What this does:** Turns on the `veth-blue` interface inside the blue namespace.

**Why we need it:** Same reason. Both ends need to be UP for data to flow.

---

## Step 3: Verify the Interfaces Are Up

Check red:

```bash
sudo ip netns exec red ip link show
```

**Expected output:**

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
6: veth-red@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 22:21:fc:9e:d0:2b brd ff:ff:ff:ff:ff:ff link-netns blue
```

Check blue:

```bash
sudo ip netns exec blue ip link show
```

**Expected output:**

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
7: veth-blue@if6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 2e:34:8e:0c:1c:6e brd ff:ff:ff:ff:ff:ff link-netns red
```

**What to look for:** Notice `UP,LOWER_UP` instead of just `M-DOWN`. That means the interface is on at both the software and hardware level. Everything is good.

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
| Bring interface up | `sudo ip netns exec <ns> ip link set <interface> up` |
| Bring interface down | `sudo ip netns exec <ns> ip link set <interface> down` |
| Check interface state | `sudo ip netns exec <ns> ip link show` |

---

**Next Lab:** [05 - Routing Between NS](../05-routing-between-ns/)
