#!/bin/bash
# Network Share Implementation Checklist

echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
echo "â•‘   SGA Network Share - Implementation Checklist        â•‘"
echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

check_mark="${GREEN}âœ“${NC}"
cross_mark="${RED}âœ—${NC}"
arrow="${YELLOW}â†’${NC}"

echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "PHASE 1: SERVER SETUP"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo ""

echo -e "${YELLOW}Server Configuration:${NC}"
echo "  Server IP: 20.0.1.9 (or your chosen server)"
echo "  Share Name: sga_shared"
echo "  Share Path: /srv/sga_shared"
echo ""

echo "Tasks:"
echo "  [ ] 1. Access server via SSH"
echo "  [ ] 2. Copy setup_server.sh to server"
echo "  [ ] 3. Run: sudo bash setup_server.sh"
echo "  [ ] 4. Set Samba password for 'sga' user"
echo "  [ ] 5. Verify Samba is running"
echo ""

echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "PHASE 2: DATA MIGRATION"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo ""

echo "Tasks:"
echo "  [ ] 1. Dry run: python3 migrate_to_shared.py --source . --dest /srv/sga_shared"
echo "  [ ] 2. Review output"
echo "  [ ] 3. Live run: python3 migrate_to_shared.py --source . --dest /srv/sga_shared --live"
echo "  [ ] 4. Verify files copied correctly"
echo ""

echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "PHASE 3: CLIENT SETUP (Repeat for each system)"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo ""

echo -e "${YELLOW}System IDs to configure:${NC}"
echo "  â€¢ admin1 (administrator) - Primary admin desk"
echo "  â€¢ admin2 (administrator) - Secondary admin desk"
echo "  â€¢ prod1  (production)    - Warehouse station 1"
echo "  â€¢ prod2  (production)    - Warehouse station 2"
echo ""

echo "For each system:"
echo "  [ ] 1. Edit setup_client.sh - Update SYSTEM_ID and SYSTEM_ROLE"
echo "  [ ] 2. Run: sudo bash setup_client.sh"
echo "  [ ] 3. Enter Samba password when prompted"
echo "  [ ] 4. Verify mount: ls -la /mnt/sga_shared/"
echo "  [ ] 5. Test write: touch /mnt/sga_shared/test_\$(hostname).txt"
echo ""

echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "PHASE 4: TESTING"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo ""

echo "Tasks:"
echo "  [ ] 1. Test file locking: python3 shared_file_manager.py"
echo "  [ ] 2. Test config: python3 shared_config_manager.py"
echo "  [ ] 3. Start app on admin1"
echo "  [ ] 4. Verify data loads correctly"
echo "  [ ] 5. Create a test label"
echo "  [ ] 6. Check history on admin2"
echo ""

echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "CURRENT STATUS"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo ""

# Check current machine
echo "Current System:"
echo "  Hostname: $(hostname)"
echo "  Current directory: $(pwd)"
echo ""

# Check if we have the files
echo "Required files:"
FILES=(
    "setup_server.sh"
    "setup_client.sh"
    "migrate_to_shared.py"
    "shared_file_manager.py"
    "shared_config_manager.py"
    "shared_config.json"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  $check_mark $file"
    else
        echo -e "  $cross_mark $file ${RED}(MISSING)${NC}"
    fi
done

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "NEXT STEP"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo ""
echo -e "${YELLOW}Choose your starting point:${NC}"
echo ""
echo "A) Start Fresh - Server Setup:"
echo "   ssh user@20.0.1.9"
echo "   # Copy setup_server.sh to server"
echo "   sudo bash setup_server.sh"
echo ""
echo "B) Testing Locally First:"
echo "   # Simulate shared folder locally"
echo "   mkdir -p /tmp/sga_shared_test"
echo "   python3 migrate_to_shared.py --source . --dest /tmp/sga_shared_test"
echo ""
echo "C) View Full Documentation:"
echo "   cat DEPLOYMENT_GUIDE.md | less"
echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
