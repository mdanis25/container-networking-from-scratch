# Lab 02: Connect Two Namespaces with a veth Pair

## Objective

Create a virtual ethernet cable (veth pair) and plug each end into a different namespace so they can talk to each other.

## Prerequisites

- Completed [Lab 01](../01-network-namespace-inspecting/)
- Two namespaces already created (`red` and `blue`)

---

## What Is a veth Pair?

A veth pair is a virtual ethernet cable. It always comes in twos — whatever goes in one end comes out the other end. Think of it like a tube with two openings. Data goes in one side and pops out the other.

We need veth pairs because namespaces are isolated by default. There is no way for `red` to send anything to `blue` without some kind of connection between them.

---

## Step 1: Make Sure the Namespaces Exist

```bash
sudo ip netns add red
sudo ip netns add blue
sudo ip netns list
```

**Expected output:**

```
blue
red
```

---

## Step 2: Create the veth Pair

```bash
sudo ip link add veth-red type veth peer name veth-blue
```

![Create veth Pair](../../assets/create-veth-pair.png)

**What this does:** Creates a virtual ethernet cable with two ends. One end is named `veth-red` and the other is `veth-blue`. Right now both ends are sitting on the host. Neither is inside any namespace yet.

**Why we need it:** Because we need a way for the two namespaces to communicate. Without this cable, they have no path to each other.

**When to use:** Every time you want to connect two namespaces or connect a namespace to the host network.

**Expected output:**

```
6: veth-red@veth-blue: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 22:21:fc:9e:d0:2b brd ff:ff:ff:ff:ff:ff
7: veth-blue@veth-red: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 2e:34:8e:0c:1c:6e brd ff:ff:ff:ff:ff:ff
```

Notice it says `state DOWN`. That just means the cable exists but nobody turned it on yet.

---

## Step 3: Plug Each End Into Its Namespace

```bash
sudo ip link set veth-blue netns blue
sudo ip link set veth-red netns red
```

![Set veth Inside Namespace](../../assets/set-veth-pair-inside-ns.png)

**What this does:** Takes the `veth-blue` end and moves it into the `blue` namespace. Takes `veth-red` and moves it into the `red` namespace. After this, neither end is on the host anymore.

**Why we need it:** A cable is useless if both ends are on the same side of the wall. We need one end in each room so both sides can actually use it.

**When to use:** Every time you create a veth pair and want to connect it to namespaces. The ends have to be moved into the right namespaces.

---

## Step 4: Verify the Connection

Check inside the blue namespace:

```bash
sudo ip netns exec blue ip link show
```

**Expected output:**

```
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
7: veth-blue@if6: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 2e:34:8e:0c:1c:6e brd ff:ff:ff:ff:ff:ff link-netns red
```

Check inside the red namespace:

```bash
sudo ip netns exec red ip link show
```

**Expected output:**

```
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
6: veth-red@if7: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 22:21:fc:9e:d0:2b brd ff:ff:ff:ff:ff:ff link-netns blue
```

Notice `link-netns red` in blue's output and `link-netns blue` in red's output. That means each side knows the other end is connected to the opposite namespace.

**Why this matters:** If you do not see the veth interface inside the namespace, it means you forgot to move it or moved it to the wrong one. Always verify.

---

## Step 5: Clean Up

```bash
sudo ip netns del red
sudo ip netns del blue
```

**What this does:** Deletes both namespaces. The veth pair gets cleaned up automatically because it was moved into the namespaces.

---

## Summary

| What | Command |
|------|---------|
| Create veth pair | `sudo ip link add <name1> type veth peer name <name2>` |
| Move end into namespace | `sudo ip link set <interface> netns <namespace>` |
| Check inside namespace | `sudo ip netns exec <namespace> ip link show` |

---

**Next Lab:** [03 - Assign IP Addresses](../03-assign-ip-addresses/)
