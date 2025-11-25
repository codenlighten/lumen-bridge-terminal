#!/bin/bash
#
# Lumen Bridge Terminal - Uninstaller
# ====================================
# Safely removes the Lumen Bridge system from your machine
#
# Usage: ./uninstall.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="lumen-daemon"

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║         🌉 LUMEN BRIDGE TERMINAL UNINSTALLER 🌉             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}This will remove:${NC}"
echo -e "  • Lumen daemon systemd service"
echo -e "  • Installation directory: $INSTALL_DIR"
echo -e "  • Environment variables from shell configs"
echo -e "  • Desktop shortcuts (if created)"
echo ""
echo -e "${CYAN}This will be preserved:${NC}"
echo -e "  • Log files (~/.lumen-daemon.log)"
echo -e "  • State files (~/.lumen-daemon-state.json)"
echo -e "  • Node.js installation"
echo ""

read -p "Continue with uninstallation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstallation cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🔧 Uninstalling Lumen Bridge...${NC}"

# Stop and disable daemon if running
if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
    echo -e "${BLUE}⏹  Stopping daemon...${NC}"
    sudo systemctl stop $SERVICE_NAME
    echo -e "${GREEN}✓${NC} Daemon stopped"
fi

if systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
    echo -e "${BLUE}🔓 Disabling daemon...${NC}"
    sudo systemctl disable $SERVICE_NAME
    echo -e "${GREEN}✓${NC} Daemon disabled"
fi

# Remove systemd service file
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    echo -e "${BLUE}🗑  Removing systemd service...${NC}"
    sudo rm -f "/etc/systemd/system/$SERVICE_NAME.service"
    sudo systemctl daemon-reload
    echo -e "${GREEN}✓${NC} Service file removed"
fi

# Remove environment variables from shell configs
echo -e "${BLUE}🧹 Cleaning shell configurations...${NC}"

for config_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
    if [ -f "$config_file" ]; then
        if grep -q "LUMENBRIDGE_URL" "$config_file"; then
            # Create backup
            cp "$config_file" "$config_file.lumen-backup"
            # Remove Lumen-related lines
            sed -i '/LUMENBRIDGE_URL/d' "$config_file"
            sed -i "\|$INSTALL_DIR|d" "$config_file"
            echo -e "${GREEN}✓${NC} Cleaned $(basename $config_file)"
        fi
    fi
done

# Remove desktop shortcuts
if [ -f "$HOME/.local/share/applications/lumen-status.desktop" ]; then
    echo -e "${BLUE}🗑  Removing desktop shortcuts...${NC}"
    rm -f "$HOME/.local/share/applications/lumen-status.desktop"
    echo -e "${GREEN}✓${NC} Desktop shortcuts removed"
fi

# Ask about removing installation directory
echo ""
read -p "Remove installation directory ($INSTALL_DIR)? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${BLUE}🗑  Removing installation directory...${NC}"
    cd "$HOME"
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓${NC} Installation directory removed"
else
    echo -e "${YELLOW}⏭  Keeping installation directory${NC}"
fi

# Ask about removing logs and state
echo ""
read -p "Remove logs and state files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🗑  Removing logs and state...${NC}"
    rm -f "$HOME/.lumen-daemon.log" "$HOME/.lumen-daemon-state.json"
    echo -e "${GREEN}✓${NC} Logs and state removed"
else
    echo -e "${YELLOW}⏭  Keeping logs and state files${NC}"
    echo -e "   Log: ~/.lumen-daemon.log"
    echo -e "   State: ~/.lumen-daemon-state.json"
fi

echo ""
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              ✅ UNINSTALLATION COMPLETE! ✅                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}Lumen Bridge has been removed from your system.${NC}"
echo ""
echo -e "${CYAN}To reinstall:${NC}"
echo -e "  ${GREEN}curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash${NC}"
echo ""
echo -e "${YELLOW}Note: Restart your terminal or run 'source ~/.bashrc' to update your environment.${NC}"
echo ""
