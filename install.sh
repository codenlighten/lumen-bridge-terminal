#!/bin/bash
#
# Lumen Bridge Terminal - One-Click Installer
# ============================================
# Installs and configures the Lumen Bridge autonomous agent system
# for Ubuntu/Debian-based systems.
#
# Usage: curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
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
    kill "$SUDO_PID" 2>/dev/null || true
    exit 1
}

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║         🌉 LUMEN BRIDGE TERMINAL INSTALLER 🌉               ║
║                                                              ║
║  Autonomous Agent OS for Your Ubuntu Laptop                 ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Detect platform and environment
echo -e "${BLUE}🔍 Detecting platform...${NC}"
IS_WSL=false
if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
    IS_WSL=true
    echo -e "${CYAN}🪟 WSL2/WSL detected${NC}"
fi

# Check if running on Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    error_exit "This installer requires apt-get (Ubuntu/Debian)" "Run on Ubuntu, Debian, or WSL2 with Ubuntu"
fi

# Detect Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "${CYAN}📋 Detected: $NAME $VERSION${NC}"
fi

# Check for sudo access and start keep-alive
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}🔐 Sudo access required for installation${NC}"
    sudo -v || error_exit "Cannot obtain sudo privileges" "Run 'sudo -v' to verify sudo access"
fi

# Sudo keep-alive loop in background
( while true; do sudo -v; sleep 60; done; ) &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null" EXIT

# Update package lists
echo -e "${BLUE}📦 Updating package lists...${NC}"
if ! sudo apt-get update -qq 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Initial update failed, trying with full output...${NC}"
    sudo apt-get update || error_exit "Failed to update package lists" "Check your internet connection and DNS settings"
fi
echo -e "${GREEN}✓${NC} Package lists updated"

# Install essential packages
echo -e "${BLUE}📦 Installing essential packages...${NC}"
ESSENTIAL_PACKAGES="curl wget git ca-certificates gnupg build-essential"
sudo apt-get install -y $ESSENTIAL_PACKAGES -qq || error_exit "Failed to install essentials" "Check apt-get logs"
echo -e "${GREEN}✓${NC} Essential packages ready"

# Check Node.js version and install if needed
echo -e "${BLUE}🔍 Checking Node.js version...${NC}"

install_node() {
    echo -e "${BLUE}📦 Installing Node.js 20 LTS...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || error_exit "Failed to add NodeSource repo" "Check internet connection"
    sudo apt-get install -y nodejs || error_exit "Node.js installation failed" "Try manual install"
}

if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found.${NC}"
    install_node
else
    # Robust version parsing
    NODE_VERSION=$(node -v 2>/dev/null | sed 's/v//' | cut -d'.' -f1)
    if [[ -n "$NODE_VERSION" && "$NODE_VERSION" -lt 18 ]]; then
        echo -e "${YELLOW}⚠️  Node.js version too old (found v$NODE_VERSION). Upgrading...${NC}"
        install_node
    else
        echo -e "${GREEN}✅ Node.js $(node -v) detected${NC}"
    fi
fi

# Clone or update repository
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📁 Existing installation found at $INSTALL_DIR${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Updating installation...${NC}"
        cd "$INSTALL_DIR"
        git pull || echo -e "${YELLOW}⚠️  Git pull failed, continuing with current version${NC}"
    else
        echo -e "${YELLOW}⏭️  Skipping update${NC}"
    fi
else
    echo -e "${BLUE}📥 Cloning repository to $INSTALL_DIR...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR" || error_exit "Failed to clone repository" "Check git URL and permissions"
fi

# ENTER INSTALL DIRECTORY (Crucial Step)
cd "$INSTALL_DIR" || error_exit "Could not enter directory $INSTALL_DIR" "Check permissions"

# Install NPM Dependencies (Crucial Step missing in original)
echo -e "${BLUE}📦 Installing Node dependencies...${NC}"
if [ -f "package.json" ]; then
    npm install --production || echo -e "${YELLOW}⚠️  NPM install had warnings (continuing)...${NC}"
else
    echo -e "${YELLOW}⚠️  No package.json found. Skipping npm install.${NC}"
fi

# Make scripts executable
echo -e "${BLUE}🔧 Setting up permissions...${NC}"
chmod +x *.sh *.js examples/*.js 2>/dev/null || true

# Check and fix locale
if ! locale -a 2>/dev/null | grep -qi "en_US.utf8\|en_US.UTF-8"; then
    echo -e "${BLUE}🌍 Setting up locale...${NC}"
    sudo apt-get install -y locales -qq 2>/dev/null || true
    sudo locale-gen en_US.UTF-8 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Locale configured"
fi

# Install useful utilities
echo -e "${BLUE}📦 Installing utilities...${NC}"
UTILITY_PACKAGES="tree htop ncdu net-tools"
sudo apt-get install -y $UTILITY_PACKAGES -qq 2>/dev/null || echo -e "${YELLOW}  Skipped optional utilities${NC}"

# Set up environment variables
echo -e "${BLUE}🌍 Configuring shell environment...${NC}"
USER_SHELL=$(basename "$SHELL")
RC_FILE=""

case "$USER_SHELL" in
    bash) RC_FILE="$HOME/.bashrc" ;;
    zsh)  RC_FILE="$HOME/.zshrc" ;;
    fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
esac

if [ -n "$RC_FILE" ]; then
    # Check if grep finds it; if not (grep returns 1), allow script to continue via || true
    if ! grep -q "LUMENBRIDGE_URL" "$RC_FILE" 2>/dev/null || true; then
        echo "" >> "$RC_FILE"
        if [ "$USER_SHELL" = "fish" ]; then
            echo "set -gx LUMENBRIDGE_URL \"$LUMENBRIDGE_URL\"" >> "$RC_FILE"
            echo "set -gx PATH \$PATH \"$INSTALL_DIR\"" >> "$RC_FILE"
        else
            echo "export LUMENBRIDGE_URL=\"$LUMENBRIDGE_URL\"" >> "$RC_FILE"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$RC_FILE"
        fi
        echo -e "${GREEN}✅ Added configuration to $RC_FILE${NC}"
    else
        echo -e "${GREEN}✅ Environment already configured in $RC_FILE${NC}"
    fi
fi

# Daemon Installation
echo ""
echo -e "${BLUE}Daemon Installation${NC}"
echo -e "${BLUE}========================${NC}"
read -p "Install Lumen Daemon as a system service? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ -f "./install-daemon.sh" ]; then
        echo -e "${BLUE}📦 Installing daemon as systemd service...${NC}"
        ./install-daemon.sh
        
        # Reload systemd to be safe
        sudo systemctl daemon-reload 2>/dev/null || true
        
        read -p "Enable daemon to start on boot? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            sudo systemctl enable lumen-daemon
            echo -e "${GREEN}✅ Daemon enabled${NC}"
        fi
        
        read -p "Start daemon now? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            sudo systemctl start lumen-daemon
            echo -e "${GREEN}✅ Daemon started${NC}"
            sleep 2
            if systemctl is-active --quiet lumen-daemon; then
                echo -e "${GREEN}✅ Service is running.${NC}"
            else
                echo -e "${RED}⚠️  Service failed to start. Check logs: journalctl -u lumen-daemon${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  install-daemon.sh not found in repo. Skipping service install.${NC}"
    fi
fi

# Custom Agent Registration
echo ""
echo -e "${BLUE}Custom Agent Registration${NC}"
echo -e "${BLUE}=============================${NC}"
read -p "Register custom specialist agents? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ -f "examples/custom-agents.js" ]; then
        echo -e "${BLUE}🚀 Registering custom agents...${NC}"
        node examples/custom-agents.js || echo -e "${YELLOW}⚠️  Agent registration encountered an issue.${NC}"
    else
        echo -e "${YELLOW}⚠️  examples/custom-agents.js not found.${NC}"
    fi
fi

# Desktop Shortcut
echo ""
read -p "Create desktop shortcuts? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    
    cat > "$DESKTOP_DIR/lumen-status.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Lumen Status
Comment=View Lumen Bridge system status
Exec=gnome-terminal -- bash -c "cd $INSTALL_DIR && ./status.sh; read -p 'Press Enter to close...'"
Icon=utilities-system-monitor
Terminal=false
Categories=System;Monitor;
EOF
    
    chmod +x "$DESKTOP_DIR/lumen-status.desktop"
    echo -e "${GREEN}✅ Desktop shortcut created${NC}"
fi

# Final status
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              ✅ INSTALLATION COMPLETE! ✅                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}📍 Installation Directory: ${GREEN}$INSTALL_DIR${NC}"
echo ""
echo -e "${YELLOW}🎯 Important Next Steps:${NC}"
echo -e "1. ${GREEN}source $RC_FILE${NC} (or restart terminal) to update your PATH."
echo -e "2. Run ${GREEN}cd $INSTALL_DIR && ./status.sh${NC} to check systems."
echo ""
echo -e "${BLUE}📚 Documentation available in README.md${NC}"
echo ""

# Post-install health check
echo -e "${BLUE}🔍 Final Health Check...${NC}"

# Check Node
if command -v node &> /dev/null; then echo -e "${GREEN}✓${NC} Node $(node -v)"; else echo -e "${RED}✗${NC} Node missing"; fi

# Check Daemon
if systemctl is-active --quiet lumen-daemon 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Daemon active"
else
    echo -e "${YELLOW}•${NC} Daemon not running (Start with: sudo systemctl start lumen-daemon)"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🌉 System Ready.${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
