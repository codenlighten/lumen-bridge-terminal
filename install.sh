#!/bin/bash
#
# Lumen Bridge Terminal - One-Click Installer
# ============================================
# FIXED:
# 1. Solves 'curl | bash' input crashing (the "cho not found" error)
# 2. Fixes missing package.json/corrupt repo
# 3. Auto-creates install-daemon.sh if missing
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

echo -e "${BLUE}🌉 LUMEN BRIDGE TERMINAL INSTALLER${NC}"

# 1. PRE-FLIGHT & SUDO
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}🔐 Sudo access required...${NC}"
    # FIX: Use < /dev/tty to fix pipe errors
    sudo -v < /dev/tty || error_exit "Sudo failed"
fi

# Keep sudo alive
( while true; do sudo -v; sleep 60; done; ) &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null" EXIT

# 2. DEPENDENCIES
echo -e "${BLUE}📦 Installing system dependencies...${NC}"
sudo apt-get update -qq 2>/dev/null || true
sudo apt-get install -y curl wget git ca-certificates gnupg build-essential -qq || error_exit "Apt failed"

# 3. NODE.JS CHECK
if ! command -v node &> /dev/null; then
    echo -e "${BLUE}📦 Installing Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 4. REPO SETUP & REPAIR
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}📁 Checking installation at $INSTALL_DIR...${NC}"
    # FIX: If package.json is missing, force reset
    if [ ! -f "$INSTALL_DIR/package.json" ]; then
        echo -e "${YELLOW}⚠️  Repo looks corrupt. Resetting...${NC}"
        cd "$INSTALL_DIR"
        git fetch --all
        git reset --hard origin/main || git pull
    else
        cd "$INSTALL_DIR"
        git pull || true
    fi
else
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 5. NPM INSTALL
echo -e "${BLUE}📦 Installing Node modules...${NC}"
if [ -f "package.json" ]; then
    npm install --production --silent || echo -e "${YELLOW}⚠️  npm warnings (safe to ignore)${NC}"
else
    # If still missing after git pull, we can't proceed with node apps
    error_exit "package.json missing" "Repository clone failed"
fi

# 6. RESTORE DAEMON SCRIPT
# We rewrite install-daemon.sh ensures it matches the version you provided
cat > install-daemon.sh << 'EOF'
#!/bin/bash
set -e
DAEMON_PATH="$(pwd)/lumen-daemon.js"
SERVICE_NAME="lumen-daemon"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "🌉 Installing Lumen Daemon Service..."
chmod +x "$DAEMON_PATH"

# Create systemd service file
sudo tee "$SERVICE_FILE" > /dev/null <<SERVICE
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
SERVICE

sudo systemctl daemon-reload
echo "✅ Service installed: $SERVICE_FILE"
EOF

chmod +x *.sh *.js examples/*.js 2>/dev/null || true

# 7. INTERACTIVE SETUP (FIXED)
echo ""
echo -e "${BLUE}Daemon Setup${NC}"

# FIX: < /dev/tty allows user input during curl pipe
if read -p "Install system service? (Y/n): " -n 1 -r < /dev/tty; then
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        ./install-daemon.sh
        
        if read -p "Start daemon now? (Y/n): " -n 1 -r < /dev/tty; then
            echo ""
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                sudo systemctl enable lumen-daemon
                sudo systemctl start lumen-daemon
                echo -e "${GREEN}✅ Daemon Started${NC}"
            fi
        fi
    fi
fi

# 8. SHELL CONFIG
RC_FILE="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && RC_FILE="$HOME/.zshrc"

if ! grep -q "LUMENBRIDGE_URL" "$RC_FILE"; then
    echo "export LUMENBRIDGE_URL=\"https://lumenbridge.xyz\"" >> "$RC_FILE"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$RC_FILE"
fi

echo ""
echo -e "${GREEN}✅ INSTALLATION COMPLETE${NC}"
echo -e "Run: ${GREEN}source $RC_FILE && cd $INSTALL_DIR && ./status.sh${NC}"
