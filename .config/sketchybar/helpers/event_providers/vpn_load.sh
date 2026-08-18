#!/bin/bash
# Detects an active VPN tunnel (Pritunl/OpenVPN tun0 or any tun/utun with peer)
# and pings the gateway to verify connectivity beyond just "connected" status.
EVENT_NAME="${1:-vpn_update}"
INTERVAL="${2:-5}"

while true; do
  # Find the first tun/utun interface that has a real peer address (point-to-point VPN)
  # utun0 is skipped — reserved by docker-mac-net-connect
  iface_info=$(ifconfig 2>/dev/null | awk '
    /^(tun[0-9]+|utun[1-9][0-9]*):/ { iface = substr($1, 1, length($1) - 1) }
    iface && /inet [1-9][0-9]*\.[0-9]/ && /-->/ { print iface " " $4; iface = ""; exit }
  ')

  if [ -z "$iface_info" ]; then
    sketchybar --trigger "$EVENT_NAME" state=disconnected ping="" gateway=""
  else
    gateway=$(echo "$iface_info" | awk '{print $2}')
    ping_ms=$(ping -c 1 -W 1000 "$gateway" 2>/dev/null | awk -F'/' '/round-trip/{printf "%d", $5}')
    if [ -n "$ping_ms" ]; then
      sketchybar --trigger "$EVENT_NAME" state=connected ping="${ping_ms}ms" gateway="$gateway"
    else
      sketchybar --trigger "$EVENT_NAME" state=timeout ping="!" gateway="$gateway"
    fi
  fi

  sleep "$INTERVAL"
done
