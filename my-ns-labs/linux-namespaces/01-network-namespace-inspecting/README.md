# Lab 01: Network Namespace Inspecting

## Objective

Create network namespaces, list them, run commands inside them, and inspect their network configuration.

## Prerequisites

- A Linux machine (Ubuntu, Debian, CentOS, etc.)
- Root access or sudo privileges

---

## What Is a Namespace Again?

A namespace is a closed-off network environment. Everything inside it — interfaces, IPs, routes, firewalls — is completely separate from the host and from other namespaces. It thinks it is the only thing on the network.

We use namespaces because without them, every container on your machine would see all the other network stuff. That is messy and insecure.

---

## Step 1: Create Two Namespaces

```bash
sudo ip netns add red
sudo ip netns add blue
```

![Create Namespaces](../../assets/create-namespace.png)

**What this does:** Creates two empty network namespaces called `red` and `blue`. Each one only has a loopback interface right now.

**Why we need it:** We want two separate network worlds. Red should not know anything about Blue and vice versa.

**When to use:** Anytime you spin up a Docker container, Kubernetes pod, or isolated environment — they all create network namespaces.

---

## Step 2: List All Namespaces

```bash
sudo ip netns list
```

**What this does:** Shows you all the network namespaces that exist on your machine.

**Expected output:**

```
blue
red
```

**Why we need it:** To verify that your namespaces were actually created. Always check after creating something.

---

## Step 3: Run a Command Inside a Namespace

```bash
sudo ip netns exec red ip link show
```

**What this does:** Goes inside the `red` namespace and shows its network interfaces. You should see only `lo` (loopback). No `eth0`, no `veth`, nothing from the host.

**Why we need it:** To prove that the namespace is isolated. It can only see its own stuff.

**Expected output:**

```
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

---

## Step 4: Check What the Host Sees

```bash
ip netns exec red ip addr
```

**What this does:** Shows the full network details inside the red namespace — interfaces, IP addresses, everything.

**Why we need it:** To see the complete picture. Right now red has no IP and no extra interfaces. It is a blank slate.

**Expected output:**

```
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

---

## Step 5: Try to Ping Loopback Inside the Namespace

```bash
sudo ip netns exec red ping -c 2 127.0.0.1
```

**What this does:** Pings the loopback address inside the red namespace.

**Why we need it:** To confirm that the loopback interface works even inside a namespace. Every namespace has its own loopback.

**Expected output:**

```
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.012 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.034 ms

--- 127.0.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.012/0.023/0.034/0.011 ms
```

---

## Step 6: Execute a Shell Inside the Namespace

```bash
sudo ip netns exec red bash
```

**What this does:** Drops you into a bash shell that is running inside the red namespace. Everything you do from here stays inside that namespace.

**Why we need it:** Sometimes you want to run multiple commands without typing `ip netns exec red` every time. This puts you inside the namespace so you can just run commands directly.

Type `exit` to leave the namespace shell.

---

## Step 7: Clean Up

```bash
sudo ip netns del red
sudo ip netns del blue
```

**What this does:** Deletes both namespaces. All interfaces, IPs, and routes inside them get removed automatically.

**Why we need it:** To clean up after yourself. You do not want old namespaces sitting around causing confusion.

---

## Summary

| What | Command |
|------|---------|
| Create namespace | `sudo ip netns add <name>` |
| List namespaces | `sudo ip netns list` |
| Run command in namespace | `sudo ip netns exec <name> <command>` |
| Open shell in namespace | `sudo ip netns exec <name> bash` |
| Delete namespace | `sudo ip netns del <name>` |

---

**Next Lab:** [02 - Connect NS with veth](../02-connect-network-ns-with-veth/)
