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
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/lumen-terminal"
LUMENBRIDGE_URL="${LUMENBRIDGE_URL:-https://lumenbridge.xyz}"
REPO_URL="https://github.com/codenlighten/lumen-bridge-terminal.git"

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

# Check if running on Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    echo -e "${RED}❌ Error: This installer requires apt-get (Ubuntu/Debian)${NC}"
    exit 1
fi

# Check Node.js version and install if needed
echo -e "${BLUE}🔍 Checking Node.js version...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found. Installing Node.js 20 LTS...${NC}"
    
    # Install Node.js using NodeSource repository
    echo -e "${BLUE}📦 Adding NodeSource repository...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    
    echo -e "${BLUE}📦 Installing Node.js...${NC}"
    sudo apt-get install -y nodejs
    
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Failed to install Node.js${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Node.js $(node -v) installed successfully${NC}"
else
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "${YELLOW}⚠️  Node.js version too old (found: $(node -v)). Upgrading to Node.js 20 LTS...${NC}"
        
        # Upgrade Node.js using NodeSource repository
        echo -e "${BLUE}📦 Adding NodeSource repository...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        
        echo -e "${BLUE}📦 Upgrading Node.js...${NC}"
        sudo apt-get install -y nodejs
        
        echo -e "${GREEN}✅ Node.js $(node -v) upgraded successfully${NC}"
    else
        echo -e "${GREEN}✅ Node.js $(node -v) detected${NC}"
    fi
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}📦 Installing git...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y git
fi

# Clone or update repository
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📁 Existing installation found at $INSTALL_DIR${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Updating installation...${NC}"
        cd "$INSTALL_DIR"
        git pull
    else
        echo -e "${YELLOW}⏭️  Skipping update${NC}"
        cd "$INSTALL_DIR"
    fi
else
    echo -e "${BLUE}📥 Cloning repository to $INSTALL_DIR...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Make scripts executable
echo -e "${BLUE}🔧 Setting up permissions...${NC}"
chmod +x terminal-optimizer.js lumen-daemon.js install-daemon.sh status.sh examples/custom-agents.js 2>/dev/null || true

# Install tree if not present
if ! command -v tree &> /dev/null; then
    echo -e "${BLUE}📦 Installing tree utility...${NC}"
    sudo apt-get install -y tree
fi

# Set up environment
echo -e "${BLUE}🌍 Configuring environment...${NC}"
if ! grep -q "LUMENBRIDGE_URL" ~/.bashrc; then
    echo "export LUMENBRIDGE_URL=\"$LUMENBRIDGE_URL\"" >> ~/.bashrc
    echo -e "${GREEN}✅ Added LUMENBRIDGE_URL to ~/.bashrc${NC}"
fi

# Offer to install as systemd service
echo ""
echo -e "${BLUE}Daemon Installation${NC}"
echo -e "${BLUE}========================${NC}"
read -p "Install Lumen Daemon as a system service? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${BLUE}📦 Installing daemon as systemd service...${NC}"
    ./install-daemon.sh
    
    read -p "Enable daemon to start on boot? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo systemctl enable lumen-daemon
        echo -e "${GREEN}✅ Daemon will start on boot${NC}"
    fi
    
    read -p "Start daemon now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo systemctl start lumen-daemon
        echo -e "${GREEN}✅ Daemon started${NC}"
        sleep 2
        sudo systemctl status lumen-daemon --no-pager -l | head -15
    fi
fi

# Offer to register custom agents
echo ""
echo -e "${BLUE}Custom Agent Registration${NC}"
echo -e "${BLUE}=============================${NC}"
read -p "Register custom specialist agents (DevWorkflow, Security, Performance)? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${BLUE}🚀 Registering custom agents...${NC}"
    node examples/custom-agents.js
fi

# Create desktop shortcut (optional)
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
    
    echo -e "${GREEN}✅ Desktop shortcut created${NC}"
fi

# Final status check
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
echo -e "${BLUE}📊 View Status: ${GREEN}cd $INSTALL_DIR && ./status.sh${NC}"
echo ""
echo -e "${YELLOW}🎯 Quick Commands:${NC}"
echo -e "  ${GREEN}cd $INSTALL_DIR${NC}"
echo -e "  ${GREEN}./status.sh${NC}                      # System status"
echo -e "  ${GREEN}node lumen-daemon.js review${NC}      # Review optimizations"
echo -e "  ${GREEN}node terminal-optimizer.js 'task'${NC} # Interactive mode"
echo -e "  ${GREEN}tail -f ~/.lumen-daemon.log${NC}      # Watch daemon activity"
echo ""

# Add to PATH suggestion
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo -e "${YELLOW}💡 Tip: Add to PATH for easier access:${NC}"
    echo -e "  ${GREEN}echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.bashrc${NC}"
    echo -e "  ${GREEN}source ~/.bashrc${NC}"
    echo ""
fi

echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "  • README.md         - Quick start guide"
echo -e "  • GUIDE.md          - Complete walkthrough"
echo -e "  • ARCHITECTURE.md   - Technical deep dive"
echo -e "  • DEPLOYMENT.md     - Current status"
echo ""

if systemctl is-active --quiet lumen-daemon 2>/dev/null; then
    echo -e "${GREEN}🤖 Daemon Status: ${GREEN}RUNNING${NC}"
    echo -e "   View logs: ${GREEN}journalctl -u lumen-daemon -f${NC}"
    echo ""
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🌉 Your laptop now has a living agent OS!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Run a quick check: ${GREEN}cd $INSTALL_DIR && node lumen-daemon.js check${NC}"
echo ""
# Force cache update
