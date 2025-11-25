#!/bin/bash
#
# Lumen Bridge - Installation Test Script
# ========================================
# Tests the installation on a fresh Ubuntu system (for CI/CD or manual testing)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Testing Lumen Bridge Installation on Fresh System        ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

INSTALL_DIR="$HOME/lumen-terminal"
TEST_FAILED=0

# Test 1: Installation directory exists
echo -n "Test 1: Installation directory... "
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    TEST_FAILED=1
fi

# Test 2: Node.js is installed
echo -n "Test 2: Node.js installed... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}✓${NC} ($NODE_VERSION)"
else
    echo -e "${RED}✗${NC}"
    TEST_FAILED=1
fi

# Test 3: Required scripts exist
echo -n "Test 3: Required scripts exist... "
REQUIRED_FILES=("terminal-optimizer.js" "lumen-daemon.js" "status.sh" "config.js" "diagnose.sh" "uninstall.sh")
MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$INSTALL_DIR/$file" ]; then
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done
if [ $MISSING_FILES -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC} ($MISSING_FILES missing)"
    TEST_FAILED=1
fi

# Test 4: Scripts are executable
echo -n "Test 4: Scripts are executable... "
EXEC_ISSUES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$INSTALL_DIR/$file" ] && [ ! -x "$INSTALL_DIR/$file" ]; then
        EXEC_ISSUES=$((EXEC_ISSUES + 1))
    fi
done
if [ $EXEC_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} ($EXEC_ISSUES not executable)"
fi

# Test 5: Can run Node.js scripts
echo -n "Test 5: Node.js scripts runnable... "
if cd "$INSTALL_DIR" && node -e "console.log('OK')" &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    TEST_FAILED=1
fi

# Test 6: Environment configured
echo -n "Test 6: Environment configured... "
if grep -q "LUMENBRIDGE_URL" ~/.bashrc 2>/dev/null || \
   grep -q "LUMENBRIDGE_URL" ~/.zshrc 2>/dev/null || \
   env | grep -q "LUMENBRIDGE_URL"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} (Not in shell config)"
fi

# Test 7: Diagnostic tool works
echo -n "Test 7: Diagnostic tool works... "
if cd "$INSTALL_DIR" && ./diagnose.sh &> /tmp/lumen-diagnose-test.log; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} (Check /tmp/lumen-diagnose-test.log)"
fi

# Test 8: Config manager works
echo -n "Test 8: Config manager works... "
if cd "$INSTALL_DIR" && node config.js show &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    TEST_FAILED=1
fi

# Test 9: Terminal optimizer syntax check
echo -n "Test 9: Terminal optimizer valid... "
if cd "$INSTALL_DIR" && node -c terminal-optimizer.js; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    TEST_FAILED=1
fi

# Test 10: Daemon syntax check
echo -n "Test 10: Daemon valid... "
if cd "$INSTALL_DIR" && node -c lumen-daemon.js; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    TEST_FAILED=1
fi

# Test 11: Internet connectivity
echo -n "Test 11: Internet connectivity... "
if curl -s --max-time 5 https://lumenbridge.xyz &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} (Cannot reach lumenbridge.xyz)"
fi

# Test 12: Essential utilities installed
echo -n "Test 12: Essential utilities... "
UTILS_OK=0
for util in git curl wget tree; do
    if command -v $util &> /dev/null; then
        UTILS_OK=$((UTILS_OK + 1))
    fi
done
if [ $UTILS_OK -ge 3 ]; then
    echo -e "${GREEN}✓${NC} ($UTILS_OK/4)"
else
    echo -e "${YELLOW}⚠${NC} ($UTILS_OK/4)"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All critical tests passed!${NC}"
    echo -e "${GREEN}Installation is ready for use.${NC}"
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    echo -e "${YELLOW}Run './diagnose.sh' for detailed diagnostics.${NC}"
fi
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Quick functionality test
echo -e "${CYAN}Quick Functionality Test:${NC}"
echo "$ cd $INSTALL_DIR && node config.js get api.baseUrl"
cd "$INSTALL_DIR" && node config.js get api.baseUrl 2>/dev/null || echo -e "${YELLOW}(Not configured yet)${NC}"
echo ""

exit $TEST_FAILED
