#!/bin/bash
# ==============================================================================
# Script Name: test_rules.sh
# Description: Verification script to audit active iptables firewall rules
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (sudo ./test_rules.sh)"
  exit 1
fi

echo "=========================================="
echo "      FIREWALL RULE AUDIT REPORT         "
echo "=========================================="

# 1. Display Default Policies
echo ""
echo "[*] Checking Default Policies..."
iptables -L | grep "Chain"

# 2. Display Active Rules with Line Numbers and Verbose Stats
echo ""
echo "[*] Active Rules Configuration:"
iptables -L -v -n --line-numbers

echo ""
echo "=========================================="
echo "[+] Audit Complete. Review chains above for DROP/ACCEPT policies."
