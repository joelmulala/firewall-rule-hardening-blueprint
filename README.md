# Firewall Rule Hardening & Default-Deny Blueprint

A production-ready network security reference architecture implementing strict **Default-Deny** traffic policies, stateful inspection, and administrative access restrictions.

## 🛡️ Architecture Overview

This repository provides a secure baseline for configuring perimeter or host-based firewalls. The architecture operates on a zero-trust mindset: all inbound traffic is blocked by default, and only explicitly authorized business services and administrative subnets are permitted.

### Core Security Principles Applied:
1. **Default-Deny Posture:** All incoming and forwarding traffic is dropped unless explicitly allowed.
2. **Stateful Inspection:** Return packets for established or related outbound connections are dynamically permitted (`ESTABLISHED,RELATED`), reducing attack surface.
3. **Privileged Access Segregation:** Administrative ports (SSH, HTTPS management) are restricted strictly to trusted internal management subnets.
4. **Rate-Limiting & Auditing:** ICMP traffic is rate-limited to mitigate ping flooding, and dropped packets are logged for SIEM ingestion.

---

## 📋 Production Rule Matrix

| Priority / Rule # | Action | Direction | Source IP / Zone | Destination IP / Zone | Port / Protocol | Service / Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **010** | **Allow** | Inbound | `Trusted_Admin_Subnet` <br>*(e.g., 192.168.10.0/24)* | Firewall Management Interface | TCP `22` (SSH), `443` (HTTPS) | Secure Management Access Only |
| **020** | **Allow** | Inbound | `Any` (Internet / LAN) | Web Server IP <br>*(e.g., 10.0.0.50)* | TCP `80` (HTTP), `443` (HTTPS) | Public Web Traffic |
| **030** | **Allow** | Inbound | Internal LAN <br>*(e.g., 192.168.20.0/24)* | Internal DNS Server | UDP/TCP `53` | Local Domain Resolution |
| **040** | **Allow** | Outbound | Internal LAN | External WAN | TCP `53`, `80`, `443` | Outbound DNS & Web Browsing |
| **999** | **Deny / Drop** | Inbound | **Any** (`0.0.0.0/0`) | **Any** (`0.0.0.0/0`) | **All** (`Any`) | **Implicit Deny All (Default Drop)** |

---

## ⚙️ Implementation Script (`iptables`)

Below is an automated hardening script utilizing Linux `iptables` to enforce the baseline security policy:

```bash
#!/bin/bash

# 1. Flush existing rules and set default policies to DROP
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 2. Allow established and related incoming connections (Stateful inspection)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 3. Allow loopback interface traffic (Local system communication)
iptables -A INPUT -i lo -j ACCEPT

# 4. Allow Secure SSH Admin Access from trusted management subnet only
iptables -A INPUT -p tcp -s 192.168.10.0/24 --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# 5. Allow Public HTTP/HTTPS traffic to web services
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

# 6. Allow ICMP Ping (limited rate to prevent flooding)
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/sec -j ACCEPT

# 7. Log dropped packets for security monitoring and SI
