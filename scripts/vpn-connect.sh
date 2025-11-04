#!/bin/bash

PASS="$HOME/vpn-configs/pass.txt"
LOGFILE="$HOME/vpn.log"

# Function to get VPN config path
get_vpn_config() {
  local vpn_name="$1"
  case "$vpn_name" in
    mmi)
      echo "$HOME/vpn-configs/andrian_binas.ovpn"
      ;;
    kl)
      echo "$HOME/vpn-configs/andrian_binas_1.ovpn"
      ;;
    *)
      echo ""
      ;;
  esac
}

case "$1" in
  start)
    if [ -z "$2" ]; then
      echo "Error: VPN name required (mmi or kl)"
      echo "Usage: $0 start {mmi|kl}"
      exit 1
    fi
    
    CONFIG=$(get_vpn_config "$2")
    if [ -z "$CONFIG" ] || [ ! -f "$CONFIG" ]; then
      echo "Error: Invalid VPN name '$2' or config file not found: $CONFIG"
      exit 1
    fi
    
    echo "Starting $2 VPN..."
    # Stop any existing VPN connection first
    if pgrep openvpn > /dev/null; then
      echo "Stopping existing VPN connection..."
      sudo killall openvpn 2>/dev/null
      sleep 2
    fi
    
    sudo openvpn --config "$CONFIG" --daemon --log "$LOGFILE"
    #sudo openvpn --config "$CONFIG" --askpass "$PASS" --daemon --log "$LOGFILE"

    sleep 2
    if pgrep openvpn > /dev/null; then
      echo "VPN ($2) is running."
      ip a | grep tun0 > /dev/null && echo "Interface tun0 is active."
      curl -s ifconfig.me && echo "  <- current public IP"
    else
      echo "Failed to start VPN. Check logs: $LOGFILE"
    fi
    ;;
  stop)
    echo "Stopping VPN..."
    sudo killall openvpn 2>/dev/null
    sleep 1
    if ! pgrep openvpn > /dev/null; then
      echo "VPN stopped."
    else
      echo "Warning: Some VPN processes may still be running."
      echo "Use 'force-stop' if needed."
    fi
    curl -s ifconfig.me && echo "  <- current public IP"
    ;;
  force-stop|forcestop)
    echo "Force stopping VPN..."
    # Try graceful stop first
    sudo killall openvpn 2>/dev/null
    sleep 1
    
    # Force kill any remaining processes
    if pgrep openvpn > /dev/null; then
      echo "Force killing remaining VPN processes..."
      sudo pkill -9 openvpn 2>/dev/null
      sudo killall -9 openvpn 2>/dev/null
      sleep 1
    fi
    
    # Check if any processes are still running
    if pgrep openvpn > /dev/null; then
      echo "Warning: Some VPN processes may still be running."
      echo "Process IDs: $(pgrep openvpn | tr '\n' ' ')"
    else
      echo "VPN forcefully stopped."
    fi
    
    # Show current IP
    curl -s ifconfig.me && echo "  <- current public IP"
    ;;
  status)
    if pgrep openvpn > /dev/null; then
      echo "VPN is running."
      ip a | grep tun0 > /dev/null && echo "Interface tun0 is active."
      curl -s ifconfig.me && echo "  <- current public IP"
    else
      echo "VPN is not running."
    fi
    ;;
  switch)
    if [ -z "$2" ]; then
      echo "Error: VPN name required (mmi or kl)"
      echo "Usage: $0 switch {mmi|kl}"
      exit 1
    fi
    
    CONFIG=$(get_vpn_config "$2")
    if [ -z "$CONFIG" ] || [ ! -f "$CONFIG" ]; then
      echo "Error: Invalid VPN name '$2' or config file not found: $CONFIG"
      exit 1
    fi
    
    # Stop existing VPN if running
    if pgrep openvpn > /dev/null; then
      echo "Switching to $2 VPN..."
      sudo killall openvpn 2>/dev/null
      sleep 2
    else
      echo "Starting $2 VPN..."
    fi
    
    sudo openvpn --config "$CONFIG" --daemon --log "$LOGFILE"
    sleep 2
    if pgrep openvpn > /dev/null; then
      echo "VPN ($2) is now active."
      ip a | grep tun0 > /dev/null && echo "Interface tun0 is active."
      curl -s ifconfig.me && echo "  <- current public IP"
    else
      echo "Failed to start VPN. Check logs: $LOGFILE"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|force-stop|status|switch} [mmi|kl]"
    echo ""
    echo "Commands:"
    echo "  start mmi|kl   - Start specified VPN"
    echo "  stop           - Stop VPN connection (graceful)"
    echo "  force-stop     - Forcefully stop VPN connection (SIGKILL)"
    echo "  status         - Check VPN status"
    echo "  switch mmi|kl  - Switch to specified VPN (stops current if running)"
    ;;
esac

# sudo openvpn --config ~/vpn-configs/roustan-3.ovpn