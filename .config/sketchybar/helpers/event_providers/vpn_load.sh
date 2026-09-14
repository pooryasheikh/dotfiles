#!/bin/bash
# Detects an active VPN tunnel (Pritunl/OpenVPN tun0 or any tun/utun with peer)
# and pings the real gateway to verify connectivity beyond just "connected" status.
EVENT_NAME="${1:-vpn_update}"
INTERVAL="${2:-5}"

while true; do
  # Find the first tun/utun interface that has a real peer address (point-to-point VPN)
  # utun0 is skipped — reserved by docker-mac-net-connect
  iface_info=$(ifconfig 2>/dev/null | awk '
    /^(tun[0-9]+|utun[1-9][0-9]*):/ { iface = substr($1, 1, length($1) - 1) }
    iface && /inet [1-9][0-9]*\.[0-9]/ && /-->/ { print iface " " $2 " " $4; iface = ""; exit }
  ')

  if [ -z "$iface_info" ]; then
    sketchybar --trigger "$EVENT_NAME" state=disconnected ping="" gateway="" iface="" local_ip=""
  else
    read -r iface local_ip peer <<< "$iface_info"
    # Some VPN clients (e.g. Pritunl/GlobalProtect on utunN) report the peer
    # as their own local address, which isn't reachable in any meaningful
    # sense — pinging it just measures the loopback, not the tunnel. Instead,
    # pull the real next-hop gateway for this interface from the routing
    # table (netstat -rn is macOS's `ip route`), skipping host (UH) routes
    # and any "gateway" that's just the interface's own address.
    gateway=$(netstat -rn -f inet 2>/dev/null | awk -v ifc="$iface" -v self="$local_ip" \
      '$NF == ifc && $3 ~ /G/ && $2 != self { print $2; exit }')
    [ -z "$gateway" ] && gateway="$peer"
    ping_ms=$(ping -c 1 -W 1000 "$gateway" 2>/dev/null | awk -F'/' '/round-trip/{printf "%d", $5}')
    if [ -n "$ping_ms" ]; then
      sketchybar --trigger "$EVENT_NAME" state=connected ping="${ping_ms}ms" gateway="$gateway" iface="$iface" local_ip="$local_ip"
    else
      sketchybar --trigger "$EVENT_NAME" state=timeout ping="!" gateway="$gateway" iface="$iface" local_ip="$local_ip"
    fi
  fi

  sleep "$INTERVAL"
done
