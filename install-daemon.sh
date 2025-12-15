#!/bin/bash
# Install Lumen Daemon as a systemd service

set -e

DAEMON_PATH="$(pwd)/lumen-daemon.js"
SERVICE_NAME="lumen-daemon"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "🌉 Installing Lumen Daemon..."

# Make daemon executable
chmod +x "$DAEMON_PATH"

# Create systemd service file
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Lumen Daemon - Autonomous System Optimization Agent
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment="LUMENBRIDGE_URL=https://lumenbridge.xyz"
Environment="NODE_ENV=production"
ExecStart=$(which node) $DAEMON_PATH start
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

echo "✅ Service installed: $SERVICE_FILE"
echo ""
echo "Commands:"
echo "  sudo systemctl start $SERVICE_NAME     # Start the daemon"
echo "  sudo systemctl enable $SERVICE_NAME    # Enable on boot"
echo "  sudo systemctl status $SERVICE_NAME    # Check status"
echo "  journalctl -u $SERVICE_NAME -f         # View logs"
echo ""
echo "Or run manually:"
echo "  node lumen-daemon.js check             # One-time check"
echo "  node lumen-daemon.js review            # Review suggestions"
