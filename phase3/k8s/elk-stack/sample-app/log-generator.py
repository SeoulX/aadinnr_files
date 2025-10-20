#!/usr/bin/env python3
"""
Sample Log Generator for ELK Stack
This application generates various types of log entries and sends them to Logstash
"""

import requests
import time
import random
import json
from datetime import datetime
import sys

# Configuration
LOGSTASH_URL = "http://logstash.local"
SERVICES = ["web-app", "api-gateway", "database", "auth-service", "payment-service", "notification-service"]
LOG_LEVELS = ["info", "warn", "error", "debug"]
USERS = ["user001", "user002", "user003", "user004", "user005"]
ENDPOINTS = ["/api/users", "/api/orders", "/api/products", "/api/auth/login", "/api/payments", "/api/notifications"]

def generate_log_entry():
    """Generate a random log entry"""
    service = random.choice(SERVICES)
    level = random.choice(LOG_LEVELS)
    user = random.choice(USERS)
    endpoint = random.choice(ENDPOINTS)
    
    # Generate different types of log messages based on level
    if level == "error":
        messages = [
            f"Database connection failed for user {user}",
            f"API endpoint {endpoint} returned 500 error",
            f"Authentication failed for user {user}",
            f"Payment processing failed for order {random.randint(1000, 9999)}",
            f"External service timeout for {service}"
        ]
    elif level == "warn":
        messages = [
            f"High response time detected for {endpoint}",
            f"Rate limit approaching for user {user}",
            f"Deprecated API endpoint {endpoint} used",
            f"Low disk space warning on {service}",
            f"Unusual activity detected for user {user}"
        ]
    elif level == "debug":
        messages = [
            f"Processing request for {endpoint}",
            f"Cache miss for user {user}",
            f"Database query executed successfully",
            f"Session created for user {user}",
            f"Configuration loaded for {service}"
        ]
    else:  # info
        messages = [
            f"User {user} logged in successfully",
            f"API request to {endpoint} completed",
            f"Order {random.randint(1000, 9999)} processed",
            f"Email sent to user {user}",
            f"Backup completed for {service}",
            f"New user registration: {user}",
            f"Payment processed for order {random.randint(1000, 9999)}",
            f"Notification sent to user {user}"
        ]
    
    message = random.choice(messages)
    
    # Create log entry
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "level": level,
        "service": service,
        "message": message,
        "user_id": user,
        "endpoint": endpoint,
        "response_time": random.randint(10, 500),
        "status_code": random.choice([200, 201, 400, 401, 404, 500]),
        "ip_address": f"192.168.1.{random.randint(1, 254)}",
        "session_id": f"session_{random.randint(10000, 99999)}",
        "request_id": f"req_{random.randint(100000, 999999)}"
    }
    
    return log_entry

def send_log_to_logstash(log_entry):
    """Send log entry to Logstash"""
    try:
        response = requests.post(LOGSTASH_URL, json=log_entry, timeout=5)
        if response.status_code == 200:
            print(f"✅ Sent: {log_entry['level'].upper()} - {log_entry['message']}")
            return True
        else:
            print(f"❌ Failed to send log: HTTP {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Connection error: {e}")
        return False

def main():
    """Main application loop"""
    print("🚀 Starting Sample Log Generator for ELK Stack")
    print(f"📡 Sending logs to: {LOGSTASH_URL}")
    print("⏹️  Press Ctrl+C to stop")
    print("-" * 50)
    
    log_count = 0
    
    try:
        while True:
            # Generate and send log entry
            log_entry = generate_log_entry()
            success = send_log_to_logstash(log_entry)
            
            if success:
                log_count += 1
            
            # Wait before sending next log (1-3 seconds)
            wait_time = random.uniform(1, 3)
            time.sleep(wait_time)
            
            # Print summary every 10 logs
            if log_count % 10 == 0:
                print(f"📊 Total logs sent: {log_count}")
                
    except KeyboardInterrupt:
        print(f"\n🛑 Stopped. Total logs sent: {log_count}")
        sys.exit(0)

if __name__ == "__main__":
    main()
