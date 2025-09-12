#!/bin/bash

case "$1" in
  start)
    echo "Starting Docker Compose"
    docker compose up -d
    ;;
  stop)
    echo "Stopping Docker Compose"
    docker compose down -v
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    ;;
esac
