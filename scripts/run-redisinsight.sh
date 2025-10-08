#!/bin/bash

# RedisInsight Runner Script
# This script runs RedisInsight GUI tool installed via snap

set -e

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if RedisInsight is installed via snap
check_redisinsight() {
    if snap list | grep -q redisinsight; then
        log_message "RedisInsight is installed via snap"
        return 0
    else
        log_message "ERROR: RedisInsight not found in snap packages"
        log_message "Please install it with: sudo snap install redisinsight"
        return 1
    fi
}

# Function to start RedisInsight
start_redisinsight() {
    log_message "Starting RedisInsight..."
    
    if check_redisinsight; then
        # Start RedisInsight in background
        nohup redisinsight > /dev/null 2>&1 &
        local pid=$!
        
        log_message "RedisInsight started with PID: $pid"
        log_message "RedisInsight should be available at: http://localhost:8001"
        log_message "To stop RedisInsight, run: kill $pid"
        
        # Save PID to file for easy stopping
        echo $pid > /tmp/redisinsight.pid
        
        return 0
    else
        return 1
    fi
}

# Function to stop RedisInsight
stop_redisinsight() {
    local pid_file="/tmp/redisinsight.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_message "RedisInsight stopped (PID: $pid)"
            rm "$pid_file"
        else
            log_message "RedisInsight process not running"
            rm "$pid_file"
        fi
    else
        log_message "No RedisInsight PID file found"
        # Try to kill any running redisinsight processes
        if pgrep -f redisinsight > /dev/null; then
            pkill -f redisinsight
            log_message "Killed existing RedisInsight processes"
        else
            log_message "No RedisInsight processes found"
        fi
    fi
}

# Function to show status
show_status() {
    local pid_file="/tmp/redisinsight.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            log_message "RedisInsight is running (PID: $pid)"
            log_message "Access at: http://localhost:8001"
        else
            log_message "RedisInsight is not running"
            rm "$pid_file"
        fi
    else
        if pgrep -f redisinsight > /dev/null; then
            log_message "RedisInsight is running (detected via process)"
            log_message "Access at: http://localhost:8001"
        else
            log_message "RedisInsight is not running"
        fi
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [start|stop|restart|status|help]"
    echo "  start   - Start RedisInsight"
    echo "  stop    - Stop RedisInsight"
    echo "  restart - Restart RedisInsight"
    echo "  status  - Show RedisInsight status"
    echo "  help    - Show this help message"
    echo ""
    echo "Requirements: RedisInsight installed via snap"
    echo "Access: http://localhost:8001"
}

# Main execution
main() {
    log_message "=== RedisInsight Runner Script ==="
    
    case "${1:-start}" in
        "start")
            start_redisinsight
            ;;
        "stop")
            stop_redisinsight
            ;;
        "restart")
            stop_redisinsight
            sleep 2
            start_redisinsight
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_message "ERROR: Unknown command '$1'. Use 'help' for usage information."
            exit 1
            ;;
    esac
    
    log_message "=== Script completed ==="
}

# Run main function with all arguments
main "$@"