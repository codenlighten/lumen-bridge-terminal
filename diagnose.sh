#!/bin/bash
#
# Lumen Bridge Terminal - Diagnostic Tool
# ========================================
# Runs comprehensive diagnostics and troubleshooting
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║         🔍 LUMEN BRIDGE DIAGNOSTIC TOOL 🔍                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

ISSUES_FOUND=0

# Function to check and report
check_item() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $name"
        return 0
    else
        echo -e "${RED}✗${NC} $name"
        if [ -n "$expected" ]; then
            echo -e "  ${YELLOW}→ $expected${NC}"
        fi
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi
}

echo -e "${CYAN}System Environment${NC}"
echo -e "${CYAN}─────────────────${NC}"
echo -e "OS: $(uname -s)"
echo -e "Kernel: $(uname -r)"
echo -e "Architecture: $(uname -m)"
echo -e "Hostname: $(hostname)"

# Check for WSL
if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
    echo -e "Environment: ${CYAN}WSL2/WSL${NC}"
fi
echo ""

echo -e "${CYAN}Dependencies${NC}"
echo -e "${CYAN}────────────${NC}"
check_item "Node.js installed" "command -v node" "Install Node.js 18+"
if command -v node &>/dev/null; then
    NODE_VERSION=$(node -v)
    echo -e "  Version: $NODE_VERSION"
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$MAJOR_VERSION" -lt 18 ]; then
        echo -e "  ${YELLOW}⚠ Node.js version should be 18 or higher${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi

check_item "npm installed" "command -v npm"
if command -v npm &>/dev/null; then
    echo -e "  Version: $(npm -v)"
fi

check_item "git installed" "command -v git"
check_item "curl installed" "command -v curl"
check_item "systemctl available" "command -v systemctl" "Required for daemon service"
echo ""

echo -e "${CYAN}Installation${NC}"
echo -e "${CYAN}────────────${NC}"
check_item "Installation directory exists" "[ -d '$INSTALL_DIR' ]"
check_item "terminal-optimizer.js exists" "[ -f '$INSTALL_DIR/terminal-optimizer.js' ]"
check_item "lumen-daemon.js exists" "[ -f '$INSTALL_DIR/lumen-daemon.js' ]"
check_item "terminal-optimizer.js executable" "[ -x '$INSTALL_DIR/terminal-optimizer.js' ]" "Run: chmod +x $INSTALL_DIR/terminal-optimizer.js"
check_item "lumen-daemon.js executable" "[ -x '$INSTALL_DIR/lumen-daemon.js' ]" "Run: chmod +x $INSTALL_DIR/lumen-daemon.js"
echo ""

echo -e "${CYAN}Configuration${NC}"
echo -e "${CYAN}─────────────${NC}"
check_item "LUMENBRIDGE_URL in environment" "env | grep -q LUMENBRIDGE_URL"

# Check shell configs
SHELL_NAME=$(basename "$SHELL")
echo -e "Current shell: $SHELL_NAME"
case "$SHELL_NAME" in
    bash)
        check_item "LUMENBRIDGE_URL in .bashrc" "grep -q LUMENBRIDGE_URL ~/.bashrc"
        ;;
    zsh)
        check_item "LUMENBRIDGE_URL in .zshrc" "grep -q LUMENBRIDGE_URL ~/.zshrc"
        ;;
    fish)
        check_item "LUMENBRIDGE_URL in config.fish" "grep -q LUMENBRIDGE_URL ~/.config/fish/config.fish"
        ;;
esac

if [ -f "$HOME/.lumen-config.json" ]; then
    echo -e "${GREEN}✓${NC} Config file exists (~/.lumen-config.json)"
else
    echo -e "${YELLOW}⚠${NC} No config file found (optional)"
fi
echo ""

echo -e "${CYAN}Daemon Service${NC}"
echo -e "${CYAN}──────────────${NC}"
if systemctl list-unit-files | grep -q lumen-daemon 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Service installed"
    
    if systemctl is-active --quiet lumen-daemon; then
        echo -e "${GREEN}✓${NC} Service running"
    else
        echo -e "${YELLOW}⚠${NC} Service installed but not running"
        echo -e "  ${CYAN}→ Start with: sudo systemctl start lumen-daemon${NC}"
    fi
    
    if systemctl is-enabled --quiet lumen-daemon 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Service enabled at boot"
    else
        echo -e "${YELLOW}⚠${NC} Service not enabled at boot"
        echo -e "  ${CYAN}→ Enable with: sudo systemctl enable lumen-daemon${NC}"
    fi
else
    echo -e "${YELLOW}⚠${NC} Daemon service not installed (optional)"
    echo -e "  ${CYAN}→ Install with: cd $INSTALL_DIR && ./install-daemon.sh${NC}"
fi
echo ""

echo -e "${CYAN}Network Connectivity${NC}"
echo -e "${CYAN}────────────────────${NC}"
LUMEN_URL="${LUMENBRIDGE_URL:-https://lumenbridge.xyz}"
check_item "Can resolve lumenbridge.xyz" "ping -c 1 lumenbridge.xyz" "Check internet connection"

if command -v curl &>/dev/null; then
    echo -n "Testing API connectivity... "
    if curl -s --max-time 10 "$LUMEN_URL/api/health" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "  ${YELLOW}→ Cannot reach $LUMEN_URL${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi
echo ""

echo -e "${CYAN}Log Files${NC}"
echo -e "${CYAN}─────────${NC}"
if [ -f "$HOME/.lumen-daemon.log" ]; then
    LOG_SIZE=$(du -h "$HOME/.lumen-daemon.log" | cut -f1)
    echo -e "${GREEN}✓${NC} Log file exists ($LOG_SIZE)"
    echo -e "  Last 5 lines:"
    tail -5 "$HOME/.lumen-daemon.log" | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠${NC} No log file yet"
fi

if [ -f "$HOME/.lumen-daemon-state.json" ]; then
    echo -e "${GREEN}✓${NC} State file exists"
else
    echo -e "${YELLOW}⚠${NC} No state file yet"
fi
echo ""

echo -e "${CYAN}Permissions${NC}"
echo -e "${CYAN}───────────${NC}"
check_item "Can write to home directory" "[ -w '$HOME' ]"
check_item "Can execute scripts" "[ -x '$INSTALL_DIR/status.sh' ]" "Run: chmod +x $INSTALL_DIR/*.sh"

if command -v sudo &>/dev/null; then
    if sudo -n true 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Passwordless sudo available"
    else
        echo -e "${YELLOW}⚠${NC} Sudo requires password (normal)"
    fi
fi
echo ""

# Summary
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}║  ✅ All checks passed! System is healthy.                 ║${NC}"
else
    echo -e "${YELLOW}║  ⚠️  Found $ISSUES_FOUND issue(s). Review output above.             ║${NC}"
fi
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $ISSUES_FOUND -gt 0 ]; then
    echo -e "${CYAN}Quick Fixes:${NC}"
    echo -e "  • Reinstall: curl -fsSL https://raw.githubusercontent.com/codenlighten/lumen-bridge-terminal/main/install.sh | bash"
    echo -e "  • Check logs: tail -f ~/.lumen-daemon.log"
    echo -e "  • Reset config: node $INSTALL_DIR/config.js reset"
    echo ""
fi

exit $ISSUES_FOUND
