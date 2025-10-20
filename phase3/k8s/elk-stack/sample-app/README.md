# Sample Log Generator for ELK Stack

This application generates realistic log entries and sends them to your Logstash instance for testing and demonstration purposes.

## Features

- **Realistic log data**: Generates various types of log entries (info, warn, error, debug)
- **Multiple services**: Simulates logs from different microservices
- **Random intervals**: Sends logs every 1-3 seconds
- **Rich metadata**: Includes user IDs, endpoints, response times, status codes, etc.
- **Continuous operation**: Runs indefinitely until stopped

## Prerequisites

- Python 3.6+
- Logstash running and accessible via ingress
- Ingress configured and /etc/hosts updated with: `192.168.39.200 logstash.local`

## Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Make script executable
chmod +x log-generator.py
```

## Usage

```bash
# Start the log generator
python3 log-generator.py
```

## Sample Log Entries

The application generates logs like:

```json
{
  "timestamp": "2025-10-11T23:30:15.123456",
  "level": "info",
  "service": "web-app",
  "message": "User user001 logged in successfully",
  "user_id": "user001",
  "endpoint": "/api/auth/login",
  "response_time": 150,
  "status_code": 200,
  "ip_address": "192.168.1.45",
  "session_id": "session_12345",
  "request_id": "req_678901"
}
```

## Log Types Generated

- **Info**: User logins, API requests, order processing, notifications
- **Warn**: High response times, rate limits, deprecated endpoints
- **Error**: Database failures, API errors, authentication failures
- **Debug**: Request processing, cache operations, configuration loading

## Services Simulated

- web-app
- api-gateway
- database
- auth-service
- payment-service
- notification-service

## Stopping the Application

Press `Ctrl+C` to stop the log generator gracefully.

## Troubleshooting

If you see connection errors:
1. Ensure Logstash is running: `kubectl get pods -n elastic-stack`
2. Check ingress status: `kubectl get ingress -n elastic-stack`
3. Verify /etc/hosts: `grep logstash.local /etc/hosts`
4. Test connection: `curl http://logstash.local`
