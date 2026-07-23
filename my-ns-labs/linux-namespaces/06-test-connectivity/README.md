# Lab 06: Test Connectivity

## Objective

Ping between the two namespaces to verify everything works, and inspect the ARP cache.

## Prerequisites

- Completed [Lab 05](../05-routing-between-ns/)
- Two namespaces with veth pair, IPs, interfaces UP, and routes set

---

## Step 1: Ping from Red to Blue

```bash
sudo ip netns exec red ping -c 5 192.168.0.2
```

**What this does:** Goes into the red namespace and sends 5 ping packets to blue's IP (`192.168.0.2`).

**Why we need it:** This is the moment of truth. If the ping works, your entire setup is correct — namespaces are isolated, veth is connected, IPs are assigned, interfaces are up, and routing works.

**Expected output:**

```
PING 192.168.0.2 (192.168.0.2) 56(84) bytes of data.
64 bytes from 192.168.0.2: icmp_seq=1 ttl=64 time=0.024 ms
64 bytes from 192.168.0.2: icmp_seq=2 ttl=64 time=0.069 ms
64 bytes from 192.168.0.2: icmp_seq=3 ttl=64 time=0.063 ms
64 bytes from 192.168.0.2: icmp_seq=4 ttl=64 time=0.064 ms
64 bytes from 192.168.0.2: icmp_seq=5 ttl=64 time=0.063 ms
^C
--- 192.168.0.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4099ms
rtt min/avg/max/mdev = 0.024/0.056/0.069/0.016 ms
```

**What to look for:** `0% packet loss` means all 5 packets made it across. If you see `100% packet loss`, something went wrong in an earlier step.

---

## Step 2: Ping from Blue to Red

```bash
sudo ip netns exec blue ping -c 5 192.168.0.1
```

**What this does:** Goes into the blue namespace and pings red's IP (`192.168.0.1`).

**Why we need it:** To confirm both directions work. Sometimes one way works but the other does not due to routing issues.

**Expected output:**

```
PING 192.168.0.1 (192.168.0.1) 56(84) bytes of data.
64 bytes from 192.168.0.1: icmp_seq=1 ttl=64 time=0.033 ms
64 bytes from 192.168.0.1: icmp_seq=2 ttl=64 time=0.072 ms
64 bytes from 192.168.0.1: icmp_seq=3 ttl=64 time=0.071 ms
64 bytes from 192.168.0.1: icmp_seq=4 ttl=64 time=0.074 ms
64 bytes from 192.168.0.1: icmp_seq=5 ttl=64 time=0.070 ms
^C
--- 192.168.0.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4099ms
rtt min/avg/max/mdev = 0.033/0.064/0.074/0.015 ms
```

---

## Step 3: Check the ARP Cache

ARP stands for Address Resolution Protocol. It is how your machine maps an IP address to a physical MAC address. The first time you ping someone, your machine asks who has this IP and the other side responds with its MAC. That mapping gets stored in the ARP cache.

Check red's ARP table:

```bash
sudo ip netns exec red arp
```

**Expected output:**

```
Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.0.2              ether   2e:34:8e:0c:1c:6e   C                     veth-red
```

Check blue's ARP table:

```bash
sudo ip netns exec blue arp
```

**Expected output:**

```
Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.0.1              ether   22:21:fc:9e:d0:2b   C                     veth-blue
```

**How to read this:**

- **Address** — The IP that was learned
- **HWaddress** — The MAC address of that IP
- **Flags** — `C` means complete and confirmed
- **Iface** — Which interface it was learned on

**Why this matters:** If you are debugging and the ping is not working, check the ARP table. If it says `incomplete`, that means the machine tried to find the other side but never got a response. That tells you the problem is at the link layer, not the routing layer.

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
| Ping from namespace | `sudo ip netns exec <ns> ping -c 5 <ip>` |
| Check ARP cache | `sudo ip netns exec <ns> arp` |

---

**Next Lab:** [07 - Bridge Network](../07-bridge-network/)
