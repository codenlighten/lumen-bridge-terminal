#!/bin/bash
#
# Lumen Bridge Terminal - One-Click Installer
# ============================================
# Installs and configures the Lumen Bridge autonomous agent system
# for Ubuntu/Debian-based systems.
#
# Usage: curl -fsSL <your_url>/install.sh | bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/lumen-terminal"
LUMENBRIDGE_URL="${LUMENBRIDGE_URL:-https://lumenbridge.xyz}"
REPO_URL="https://github.com/codenlighten/lumen-bridge-terminal.git"

# Error handler
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
    echo -e "${YELLOW}💡 Troubleshooting: $2${NC}" >&2
    # Kill sudo keep-alive if running
    if [ -n "$SUDO_PID" ]; then kill "$SUDO_PID" 2>/dev/null || true; fi
    exit 1
}

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║         🌉 LUMEN BRIDGE TERMINAL INSTALLER 🌉               ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 1. PRE-FLIGHT CHECKS
# --------------------

# Check for sudo access and start keep-alive
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}🔐 Sudo access required for installation${NC}"
    # Use < /dev/tty to allow password entry even if script is piped via curl
    sudo -v < /dev/tty || error_exit "Cannot obtain sudo privileges" "Run 'sudo -v' manually first"
fi

# Keep sudo alive in background
( while true; do sudo -v; sleep 60; done; ) &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null" EXIT

# Update package lists
echo -e "${BLUE}📦 Updating package lists...${NC}"
sudo apt-get update -qq 2>/dev/null || true

# Install system dependencies
echo -e "${BLUE}📦 Installing essential packages...${NC}"
sudo apt-get install -y curl wget git ca-certificates gnupg build-essential -qq || error_exit "Failed to install essentials" "Check apt-get logs"

# 2. NODE.JS INSTALLATION
# -----------------------
echo -e "${BLUE}🔍 Checking Node.js environment...${NC}"

install_node() {
    echo -e "${BLUE}📦 Installing Node.js 20 LTS...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 
    sudo apt-get install -y nodejs || error_exit "Node.js install failed" "Try manual install"
}

if ! command -v node &> /dev/null; then
    install_node
else
    # Robust version parsing
    NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VER" -lt 18 ]; then
        echo -e "${YELLOW}⚠️  Node.js version $NODE_VER is too old. Upgrading...${NC}"
        install_node
    else
        echo -e "${GREEN}✅ Node.js $(node -v) detected${NC}"
    fi
fi

# 3. REPOSITORY SETUP
# -------------------
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📁 Existing installation found at $INSTALL_DIR${NC}"
    
    # Check for corruption (missing package.json)
    if [ ! -f "$INSTALL_DIR/package.json" ]; then
        echo -e "${YELLOW}⚠️  Installation looks corrupt (missing package.json). Repairing...${NC}"
        cd "$INSTALL_DIR"
        git fetch --all
        git reset --hard origin/main || error_exit "Failed to repair repo" "Delete $INSTALL_DIR and retry"
    else
        echo -e "${BLUE}🔄 Updating repository...${NC}"
        cd "$INSTALL_DIR"
        git pull || echo -e "${YELLOW}⚠️  Git pull failed, continuing with current files...${NC}"
    fi
else
    echo -e "${BLUE}📥 Cloning repository...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR" || error_exit "Failed to clone repository" "Check git URL"
fi

# 4. DEPENDENCY INSTALLATION
# --------------------------
echo -e "${BLUE}🔧 Configuring installation...${NC}"
cd "$INSTALL_DIR" || error_exit "Could not enter $INSTALL_DIR" "Check permissions"

if [ -f "package.json" ]; then
    echo -e "${BLUE}📦 Installing Node dependencies (npm install)...${NC}"
    npm install --production --silent || echo -e "${YELLOW}⚠️  npm install completed with warnings${NC}"
else
    echo -e "${RED}❌ Fatal: package.json still missing after clone.${NC}"
    exit 1
fi

# Make scripts executable
chmod +x *.sh *.js examples/*.js 2>/dev/null || true

# 5. INTERACTIVE CONFIGURATION
# ----------------------------
# Note: We use < /dev/tty for all read commands to fix the 'cho' error when piping from curl

echo ""
echo -e "${BLUE}Daemon Configuration${NC}"
echo -e "${BLUE}====================${NC}"

if read -p "Install Lumen Daemon as a system service? (Y/n): " -n 1 -r < /dev/tty; then
    echo "" 
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${BLUE}⚙️  Configuring systemd...${NC}"
        
        # Ensure the install script exists, if not create a stub for safety
        if [ ! -f "./install-daemon.sh" ]; then
             echo -e "${YELLOW}⚠️  install-daemon.sh missing. Creating generic service file...${NC}"
             # Logic to create service file manually if script is missing
             sudo bash -c "cat > /etc/systemd/system/lumen-daemon.service << EOF
[Unit]
Description=Lumen Bridge Daemon
After=network.target

[Service]
ExecStart=$(which node) $INSTALL_DIR/lumen-daemon.js
WorkingDirectory=$INSTALL_DIR
Restart=always
User=$USER
Environment=PATH=$PATH
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF"
        else
            ./install-daemon.sh
        fi

        sudo systemctl daemon-reload 2>/dev/null || true
        
        if read -p "Enable daemon to start on boot? (Y/n): " -n 1 -r < /dev/tty; then
            echo ""
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                sudo systemctl enable lumen-daemon
                echo -e "${GREEN}✅ Daemon enabled on boot${NC}"
            fi
        fi

        if read -p "Start daemon now? (Y/n): " -n 1 -r < /dev/tty; then
            echo ""
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                sudo systemctl start lumen-daemon
                echo -e "${GREEN}✅ Daemon started${NC}"
            fi
        fi
    fi
else
    echo "" # Fallback if read fails
fi

echo ""
echo -e "${BLUE}Agent Configuration${NC}"
if read -p "Register custom specialist agents? (Y/n): " -n 1 -r < /dev/tty; then
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if [ -f "examples/custom-agents.js" ]; then
            node examples/custom-agents.js
        fi
    fi
fi

# 6. SHELL CONFIGURATION
# ----------------------
echo -e "${BLUE}🌍 Configuring Shell Environment...${NC}"
RC_FILE="$HOME/.bashrc"
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
    RC_FILE="$HOME/.zshrc"
fi

if ! grep -q "LUMENBRIDGE_URL" "$RC_FILE" 2>/dev/null || true; then
    echo >> "$RC_FILE"
    echo "# Lumen Bridge Configuration" >> "$RC_FILE"
    echo "export LUMENBRIDGE_URL=\"$LUMENBRIDGE_URL\"" >> "$RC_FILE"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$RC_FILE"
    echo -e "${GREEN}✅ Path added to $RC_FILE${NC}"
else
    echo -e "${GREEN}✅ Environment already configured${NC}"
fi

# 7. FINAL SUMMARY
# ----------------
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║              ✅ INSTALLATION COMPLETE! ✅                    ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo -e "${BLUE}📍 Location:${NC} $INSTALL_DIR"
echo -e "${BLUE}👉 Next Steps:${NC}"
echo -e "   1. Reload shell:  ${GREEN}source $RC_FILE${NC}"
echo -e "   2. Check status:  ${GREEN}cd $INSTALL_DIR && ./status.sh${NC}"
echo ""
