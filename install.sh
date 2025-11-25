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

# Spinner for long operations
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Error handler
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
    echo -e "${YELLOW}💡 Troubleshooting: $2${NC}" >&2
    exit 1
}

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

# Check for sudo access
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}🔐 Sudo access required for installation${NC}"
    sudo -v || error_exit "Cannot obtain sudo privileges" "Run 'sudo -v' to verify sudo access"
fi

# Check Node.js version and install if needed
echo -e "${BLUE}🔍 Checking Node.js version...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found. Installing Node.js 20 LTS...${NC}"
    
    # Install Node.js using NodeSource repository with retry logic
    echo -e "${BLUE}📦 Adding NodeSource repository...${NC}"
    RETRY_COUNT=0
    MAX_RETRIES=3
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -; then
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo -e "${YELLOW}⚠️  Retry $RETRY_COUNT/$MAX_RETRIES...${NC}"
            sleep 2
        fi
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        error_exit "Failed to add NodeSource repository" "Check your internet connection and try again"
    fi
    
    echo -e "${BLUE}📦 Installing Node.js...${NC}"
    sudo apt-get install -y nodejs || error_exit "Node.js installation failed" "Try 'sudo apt-get update && sudo apt-get install nodejs'"
    
    if ! command -v node &> /dev/null; then
        error_exit "Node.js installation verification failed" "Manually install Node.js 18+ and retry"
    fi
    echo -e "${GREEN}✅ Node.js $(node -v) installed successfully${NC}"
else
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "${YELLOW}⚠️  Node.js version too old (found: $(node -v)). Upgrading to Node.js 20 LTS...${NC}"
        
        echo -e "${BLUE}📦 Adding NodeSource repository...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || error_exit "Failed to add NodeSource repository" "Check your internet connection"
        
        echo -e "${BLUE}📦 Upgrading Node.js...${NC}"
        sudo apt-get install -y nodejs || error_exit "Node.js upgrade failed" "Try manually: sudo apt-get update && sudo apt-get install nodejs"
        
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
chmod +x terminal-optimizer.js lumen-daemon.js config.js install-daemon.sh status.sh diagnose.sh uninstall.sh examples/custom-agents.js 2>/dev/null || true

# Install tree if not present
if ! command -v tree &> /dev/null; then
    echo -e "${BLUE}📦 Installing tree utility...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y tree
fi

# Set up environment for multiple shells
echo -e "${BLUE}🌍 Configuring environment...${NC}"

# Detect user's shell
USER_SHELL=$(basename "$SHELL")
echo -e "${CYAN}🐚 Detected shell: $USER_SHELL${NC}"

# Configure based on shell
case "$USER_SHELL" in
    bash)
        SHELL_RC="$HOME/.bashrc"
        if ! grep -q "LUMENBRIDGE_URL" "$SHELL_RC" 2>/dev/null; then
            echo "export LUMENBRIDGE_URL=\"$LUMENBRIDGE_URL\"" >> "$SHELL_RC"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
            echo -e "${GREEN}✅ Added configuration to ~/.bashrc${NC}"
        fi
        ;;
    zsh)
        SHELL_RC="$HOME/.zshrc"
        if ! grep -q "LUMENBRIDGE_URL" "$SHELL_RC" 2>/dev/null; then
            echo "export LUMENBRIDGE_URL=\"$LUMENBRIDGE_URL\"" >> "$SHELL_RC"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
            echo -e "${GREEN}✅ Added configuration to ~/.zshrc${NC}"
        fi
        ;;
    fish)
        FISH_CONFIG="$HOME/.config/fish/config.fish"
        mkdir -p "$(dirname "$FISH_CONFIG")"
        if ! grep -q "LUMENBRIDGE_URL" "$FISH_CONFIG" 2>/dev/null; then
            echo "set -gx LUMENBRIDGE_URL \"$LUMENBRIDGE_URL\"" >> "$FISH_CONFIG"
            echo "set -gx PATH \$PATH \"$INSTALL_DIR\"" >> "$FISH_CONFIG"
            echo -e "${GREEN}✅ Added configuration to ~/.config/fish/config.fish${NC}"
        fi
        ;;
    *)
        echo -e "${YELLOW}⚠️  Unknown shell: $USER_SHELL. Add manually:${NC}"
        echo -e "${CYAN}export LUMENBRIDGE_URL=\"$LUMENBRIDGE_URL\"${NC}"
        ;;
esac

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

# Run post-install health check
echo -e "${BLUE}🔍 Running post-install health check...${NC}"
HEALTH_CHECK_PASSED=true

# Check Node.js
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓${NC} Node.js $(node -v)"
else
    echo -e "${RED}✗${NC} Node.js not found"
    HEALTH_CHECK_PASSED=false
fi

# Check installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}✓${NC} Installation directory: $INSTALL_DIR"
else
    echo -e "${RED}✗${NC} Installation directory missing"
    HEALTH_CHECK_PASSED=false
fi

# Check executables
for script in terminal-optimizer.js lumen-daemon.js status.sh; do
    if [ -x "$INSTALL_DIR/$script" ]; then
        echo -e "${GREEN}✓${NC} $script is executable"
    else
        echo -e "${YELLOW}⚠${NC} $script not executable"
    fi
done

# Check environment variable
if grep -q "LUMENBRIDGE_URL" "$HOME/.bashrc" 2>/dev/null || \
   grep -q "LUMENBRIDGE_URL" "$HOME/.zshrc" 2>/dev/null || \
   grep -q "LUMENBRIDGE_URL" "$HOME/.config/fish/config.fish" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Environment configured"
else
    echo -e "${YELLOW}⚠${NC} Environment may need manual configuration"
fi

# Check daemon if installed
if systemctl is-active --quiet lumen-daemon 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Lumen daemon is running"
elif systemctl list-unit-files | grep -q lumen-daemon 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Lumen daemon installed but not running"
fi

echo ""
if [ "$HEALTH_CHECK_PASSED" = true ]; then
    echo -e "${GREEN}✅ All health checks passed!${NC}"
else
    echo -e "${YELLOW}⚠️  Some checks failed. Review above for details.${NC}"
fi
echo ""

echo -e "Run a quick check: ${GREEN}cd $INSTALL_DIR && node lumen-daemon.js check${NC}"
echo -e "Uninstall anytime: ${CYAN}$INSTALL_DIR/uninstall.sh${NC}"
echo ""
# Force cache update
