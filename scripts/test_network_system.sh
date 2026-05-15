#!/bin/bash
# Network Share System - Complete Test Script
# Tests all components of the network share infrastructure

echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
echo "â•‘   SGA Network Share System - Comprehensive Test          â•‘"
echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0
WARNINGS=0

# Test function
test_item() {
    echo -n "Testing: $1 ... "
}

pass() {
    echo -e "${GREEN}âœ“ PASS${NC}"
    ((PASSED++))
}

fail() {
    echo -e "${RED}âœ— FAIL${NC}"
    if [ ! -z "$1" ]; then
        echo "  Error: $1"
    fi
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}âš  WARNING${NC}"
    if [ ! -z "$1" ]; then
        echo "  Warning: $1"
    fi
    ((WARNINGS++))
}

echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "1. File Existence Tests"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

test_item "shared_config.json exists"
if [ -f "shared_config.json" ]; then
    pass
else
    fail "Configuration file not found"
fi

test_item "network_share_manager.py exists"
if [ -f "network_share_manager.py" ]; then
    pass
else
    fail "Network manager not found"
fi

test_item "network_status_widget.py exists"
if [ -f "network_status_widget.py" ]; then
    pass
else
    fail "Status widget not found"
fi

test_item "shared_config_manager.py exists"
if [ -f "shared_config_manager.py" ]; then
    pass
else
    fail "Config manager not found"
fi

test_item "shared_file_manager.py exists"
if [ -f "shared_file_manager.py" ]; then
    pass
else
    fail "File manager not found"
fi

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "2. Python Module Import Tests"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

test_item "Import network_share_manager"
if python3 -c "from network_share_manager import NetworkShareManager" 2>/dev/null; then
    pass
else
    fail "Cannot import NetworkShareManager"
fi

test_item "Import network_status_widget"
if python3 -c "from network_status_widget import NetworkStatusWidget" 2>/dev/null; then
    pass
else
    fail "Cannot import NetworkStatusWidget"
fi

test_item "Import shared_config_manager"
if python3 -c "from shared_config_manager import SharedConfigManager" 2>/dev/null; then
    pass
else
    fail "Cannot import SharedConfigManager"
fi

test_item "Import shared_file_manager"
if python3 -c "from shared_file_manager import SharedFileManager" 2>/dev/null; then
    pass
else
    fail "Cannot import SharedFileManager"
fi

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "3. Configuration Tests"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

test_item "Configuration file is valid JSON"
if python3 -c "import json; json.load(open('shared_config.json'))" 2>/dev/null; then
    pass
else
    fail "Invalid JSON in shared_config.json"
fi

test_item "Configuration has network section"
if python3 -c "import json; c=json.load(open('shared_config.json')); assert 'network' in c" 2>/dev/null; then
    pass
else
    fail "No network section in config"
fi

test_item "Configuration has server_address"
if python3 -c "import json; c=json.load(open('shared_config.json')); assert 'server_address' in c['network']" 2>/dev/null; then
    pass
else
    fail "No server_address in network config"
fi

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "4. Network Manager Functionality Tests"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

test_item "NetworkShareManager initialization"
if python3 -c "from network_share_manager import NetworkShareManager; m = NetworkShareManager('shared_config.json')" 2>/dev/null; then
    pass
else
    fail "Cannot initialize NetworkShareManager"
fi

test_item "NetworkShareManager.check_status()"
if python3 -c "from network_share_manager import NetworkShareManager; m = NetworkShareManager('shared_config.json'); s = m.check_status()" 2>/dev/null; then
    pass
else
    fail "check_status() failed"
fi

test_item "Script generation works"
if python3 network_share_manager.py --generate-scripts 2>&1 | grep -q "successfully"; then
    pass
else
    fail "Script generation failed"
fi

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "5. Generated Files Tests"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

test_item "mount_share.sh generated"
if [ -f "mount_share.sh" ]; then
    pass
else
    warn "mount_share.sh not found (run --generate-scripts)"
fi

test_item "mount_share.sh is executable"
if [ -x "mount_share.sh" ]; then
    pass
else
    warn "mount_share.sh not executable"
fi

test_item "sga-credentials.template generated"
if [ -f "sga-credentials.template" ]; then
    pass
else
    warn "sga-credentials.template not found"
fi

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "6. Network Connectivity Tests"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

# Extract server address from config
SERVER=$(python3 -c "import json; c=json.load(open('shared_config.json')); print(c['network']['server_address'])" 2>/dev/null)

test_item "Server address configured ($SERVER)"
if [ ! -z "$SERVER" ]; then
    pass
else
    fail "No server address in config"
fi

test_item "Server is reachable (ping)"
if ping -c 1 -W 2 "$SERVER" >/dev/null 2>&1; then
    pass
else
    warn "Server $SERVER not reachable"
fi

test_item "Mount point directory"
MOUNT_PATH=$(python3 -c "import json; c=json.load(open('shared_config.json')); print(c['network']['mount_path'])" 2>/dev/null)
if [ -d "$MOUNT_PATH" ]; then
    pass
else
    warn "Mount point $MOUNT_PATH does not exist"
fi

test_item "Share is mounted"
if mountpoint -q "$MOUNT_PATH" 2>/dev/null; then
    pass
else
    warn "Share not currently mounted at $MOUNT_PATH"
fi

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "7. Documentation Tests"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

test_item "NETWORK_SHARE_GUIDE.md exists"
if [ -f "NETWORK_SHARE_GUIDE.md" ]; then
    pass
else
    warn "User guide not found"
fi

test_item "NETWORK_IMPLEMENTATION_SUMMARY.md exists"
if [ -f "NETWORK_IMPLEMENTATION_SUMMARY.md" ]; then
    pass
else
    warn "Implementation summary not found"
fi

test_item "network_integration_example.py exists"
if [ -f "network_integration_example.py" ]; then
    pass
else
    warn "Integration example not found"
fi

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "8. CLI Tool Tests"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

test_item "CLI --status works"
if python3 network_share_manager.py --status >/dev/null 2>&1; then
    pass
else
    fail "CLI --status command failed"
fi

test_item "CLI --diagnose works"
if python3 network_share_manager.py --diagnose >/dev/null 2>&1; then
    pass
else
    fail "CLI --diagnose command failed"
fi

echo ""
echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
echo "â•‘                    TEST SUMMARY                           â•‘"
echo "â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•£"
echo "â•‘                                                           â•‘"
printf "â•‘  ${GREEN}âœ“ Passed:${NC}    %-2d                                        â•‘\n" "$PASSED"
printf "â•‘  ${RED}âœ— Failed:${NC}    %-2d                                        â•‘\n" "$FAILED"
printf "â•‘  ${YELLOW}âš  Warnings:${NC}  %-2d                                        â•‘\n" "$WARNINGS"
echo "â•‘                                                           â•‘"
echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo ""

# Overall result
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All critical tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review warnings (if any)"
    echo "  2. Configure credentials: edit sga-credentials.template"
    echo "  3. Mount the share: ./mount_share.sh"
    echo "  4. Test with GUI: python3 network_integration_example.py --test"
    echo ""
    exit 0
else
    echo -e "${RED}Some tests failed. Please review errors above.${NC}"
    echo ""
    echo "For help:"
    echo "  - Read NETWORK_SHARE_GUIDE.md"
    echo "  - Run: python3 network_share_manager.py --diagnose"
    echo ""
    exit 1
fi
