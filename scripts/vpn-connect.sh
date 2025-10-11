#!/bin/bash

CONFIG="$HOME/vpn-configs/andrian_binas.ovpn"
# CONFIG="$HOME/vpn-configs/jericko_razal.ovpn"
PASS="$HOME/vpn-configs/pass.txt"
LOGFILE="$HOME/vpn.log"

case "$1" in
  start)
    echo "Starting VPN..."
    sudo openvpn --config "$CONFIG" --daemon --log "$LOGFILE"
    #sudo openvpn --config "$CONFIG" --askpass "$PASS" --daemon --log "$LOGFILE"

    if pgrep openvpn > /dev/null; then
      echo "VPN is running."
      ip a | grep tun0 > /dev/null && echo "Interface tun0 is active."
      curl -s ifconfig.me && echo "  <- current public IP"
    fi
    ;;
  stop)
    echo "Stopping VPN..."
    sudo killall openvpn
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
  *)
    echo "Usage: $0 {start|stop|status}"
    ;;
esac

# sudo openvpn --config ~/vpn-configs/roustan-3.ovpn