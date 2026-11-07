#!/bin/bash
# ==============================================================================
# Script Name: hardening_rules.sh
# Description: Production-grade Linux firewall hardening script using iptables
# Framework Alignment: NIST SP 800-41 Rev. 1 (Firewall Guidelines)
# ==============================================================================

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (sudo ./hardening_rules.sh)"
  exit 1
fi

echo "[+] Starting Firewall Hardening Application..."

# 1. Flush existing rules and reset counters
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# 2. Set Default Policies (Zero-Trust Default Deny)
echo "[*] Setting default policies to DROP..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 3. Allow Loopback Traffic (Internal IPC)
echo "[+] Allowing loopback traffic..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# 4. Allow Established and Related Incoming Connections (Stateful Inspection)
echo "[+] Enabling stateful connection tracking..."
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 5. Allow SSH (Port 22) with Rate Limiting (Brute-Force Protection)
echo "[+] Hardening SSH access with rate limiting..."
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# 6. Allow Web Traffic (HTTP/HTTPS)
echo "[+] Opening ports 80 (HTTP) and 443 (HTTPS)..."
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

# 7. Mitigate Common Scans & Flood Attacks (DoS Prevention)
echo "[+] Applying anti-spoofing and port scan protections..."
# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
# Drop XMAS and NULL scans
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# Limit ICMP (Ping) flood protection
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

echo "[+] Firewall hardening rules applied successfully!"
