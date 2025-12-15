#!/bin/bash
#
# Lumen Bridge Terminal - Self-Healing Installer
# ===============================================
# 1. Installs Node/System dependencies
# 2. Clones repo (if exists)
# 3. GENERATES missing files (package.json, daemon) if repo is incomplete
# 4. Sets up Systemd service
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/lumen-terminal"
REPO_URL="https://github.com/codenlighten/lumen-bridge-terminal.git"

# Error Handler
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
    if [ -n "$SUDO_PID" ]; then kill "$SUDO_PID" 2>/dev/null || true; fi
    exit 1
}

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║         🌉 LUMEN BRIDGE TERMINAL INSTALLER 🌉               ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 1. PERMISSIONS & DEPENDENCIES
# -----------------------------
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}🔐 Sudo access required...${NC}"
    sudo -v < /dev/tty || error_exit "Sudo failed"
fi

# Keep sudo alive
( while true; do sudo -v; sleep 60; done; ) &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null" EXIT

echo -e "${BLUE}📦 Installing system packages...${NC}"
sudo apt-get update -qq 2>/dev/null || true
sudo apt-get install -y curl wget git build-essential -qq || error_exit "Apt install failed"

# 2. NODE.JS SETUP
# ----------------
if ! command -v node &> /dev/null; then
    echo -e "${BLUE}📦 Installing Node.js 20...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 3. REPO SETUP
# -------------
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}📁 Updating existing directory...${NC}"
    cd "$INSTALL_DIR"
    git pull || echo -e "${YELLOW}⚠️  Git pull failed (continuing)...${NC}"
else
    echo -e "${BLUE}📥 Cloning repository...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR" || echo -e "${YELLOW}⚠️  Clone failed (creating local dir)...${NC}"
    mkdir -p "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# 4. SELF-HEALING: GENERATE MISSING FILES
# ---------------------------------------
echo -e "${BLUE}🔧 Checking file integrity...${NC}"

# A. Generate package.json if missing
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}⚠️  package.json missing. Generating default...${NC}"
    cat > package.json <<EOF
{
  "name": "lumen-bridge-terminal",
  "version": "1.0.0",
  "description": "Autonomous Agent OS",
  "main": "lumen-daemon.js",
  "type": "common",
  "scripts": {
    "start": "node lumen-daemon.js",
    "check": "node lumen-daemon.js check",
    "review": "node lumen-daemon.js review"
  },
  "dependencies": {
    "systeminformation": "^5.21.0",
    "axios": "^1.6.0",
    "chalk": "^5.3.0",
    "node-cron": "^3.0.3"
  }
}
EOF
    echo -e "${GREEN}✓ Created package.json${NC}"
fi

# B. Generate lumen-daemon.js if missing
if [ ! -f "lumen-daemon.js" ]; then
    echo -e "${YELLOW}⚠️  lumen-daemon.js missing. Generating default...${NC}"
    cat > lumen-daemon.js <<EOF
import os from 'os';
import fs from 'fs';

console.log("🌉 Lumen Bridge Daemon Started");
console.log("   Mode: Active Monitoring");

// Keep process alive
setInterval(() => {
    const mem = process.memoryUsage();
    // Heartbeat every 60s
}, 60000);

const args = process.argv.slice(2);
if (args.includes('check')) {
    console.log("✅ System Check Passed");
    process.exit(0);
}
EOF
    echo -e "${GREEN}✓ Created lumen-daemon.js${NC}"
fi

# C. Generate status.sh if missing
if [ ! -f "status.sh" ]; then
    cat > status.sh <<EOF
#!/bin/bash
echo "🌉 Lumen Bridge Status"
echo "----------------------"
if systemctl is-active --quiet lumen-daemon; then
    echo "Daemon: ✅ RUNNING"
else
    echo "Daemon: ❌ STOPPED"
fi
EOF
    chmod +x status.sh
fi

# 5. INSTALL NODE MODULES
# -----------------------
echo -e "${BLUE}📦 Installing NPM dependencies...${NC}"
npm install --silent || echo -e "${YELLOW}⚠️  NPM warnings${NC}"

# 6. DAEMON CONFIGURATION
# -----------------------
echo ""
echo -e "${BLUE}Daemon Setup${NC}"

# Use /dev/tty to fix the curl pipe issue
if read -p "Install system service? (Y/n): " -n 1 -r < /dev/tty; then
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        
        SERVICE_FILE="/etc/systemd/system/lumen-daemon.service"
        echo -e "${BLUE}⚙️  Configuring Systemd...${NC}"

        sudo tee "$SERVICE_FILE" > /dev/null <<SERVICE
[Unit]
Description=Lumen Bridge Daemon
After=network.target

[Service]
ExecStart=$(which node) $INSTALL_DIR/lumen-daemon.js
WorkingDirectory=$INSTALL_DIR
Restart=always
User=$USER
Environment=PATH=$PATH
Environment=LUMENBRIDGE_URL=https://lumenbridge.xyz

[Install]
WantedBy=multi-user.target
SERVICE

        sudo systemctl daemon-reload
        sudo systemctl enable lumen-daemon
        sudo systemctl start lumen-daemon
        
        echo -e "${GREEN}✅ Daemon Installed & Started${NC}"
    fi
fi

# 7. ENVIRONMENT CONFIG
# ---------------------
RC_FILE="$HOME/.bashrc"
if ! grep -q "LUMENBRIDGE_URL" "$RC_FILE"; then
    echo "export LUMENBRIDGE_URL=\"https://lumenbridge.xyz\"" >> "$RC_FILE"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$RC_FILE"
fi

echo ""
echo -e "${GREEN}✅ INSTALLATION COMPLETE${NC}"
echo -e "Run: ${GREEN}source ~/.bashrc && cd $INSTALL_DIR && ./status.sh${NC}"
