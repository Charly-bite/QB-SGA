#!/bin/bash
# Server-Side Setup Script for SGA Network Share
# Run this script ON THE SERVER (20.0.1.9) as root
# 
# Usage: 
#   1. Copy this file to the server: scp setup_server_share.sh user@20.0.1.9:/tmp/
#   2. SSH to server: ssh user@20.0.1.9
#   3. Run as root: sudo bash /tmp/setup_server_share.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${BLUE}â•‘${NC}     SGA Network Share - Server Setup (20.0.1.9)            ${BLUE}â•‘${NC}"
echo -e "${BLUE}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}âœ— This script must be run as root${NC}"
    echo "  Please run: sudo bash $0"
    exit 1
fi

# Configuration
SHARE_NAME="sga_shared"
SHARE_PATH="/srv/sga_shared"
SGA_USER="sga"
SGA_GROUP="sga"

echo -e "${BLUE}Configuration:${NC}"
echo "  Share Name: $SHARE_NAME"
echo "  Share Path: $SHARE_PATH"
echo "  User/Group: $SGA_USER"
echo ""

# ============================================================================
# STEP 1: Create SGA User and Group
# ============================================================================
echo -e "${YELLOW}â”â”â” STEP 1: Creating SGA User and Group â”â”â”${NC}"

# Create group if doesn't exist
if ! getent group $SGA_GROUP > /dev/null 2>&1; then
    echo "Creating group: $SGA_GROUP"
    groupadd $SGA_GROUP
    echo -e "${GREEN}âœ“ Group created${NC}"
else
    echo -e "${GREEN}âœ“ Group already exists${NC}"
fi

# Create user if doesn't exist
if ! id -u $SGA_USER > /dev/null 2>&1; then
    echo "Creating user: $SGA_USER"
    useradd -M -s /sbin/nologin -g $SGA_GROUP $SGA_USER
    echo -e "${GREEN}âœ“ User created${NC}"
else
    echo -e "${GREEN}âœ“ User already exists${NC}"
fi

# ============================================================================
# STEP 2: Create Share Directory Structure
# ============================================================================
echo ""
echo -e "${YELLOW}â”â”â” STEP 2: Creating Share Directory Structure â”â”â”${NC}"

# Create main directory
mkdir -p $SHARE_PATH
echo -e "${GREEN}âœ“ Created: $SHARE_PATH${NC}"

# Create subdirectories
mkdir -p $SHARE_PATH/master_data
mkdir -p $SHARE_PATH/master_data/unified_db
mkdir -p $SHARE_PATH/master_data/original_data
mkdir -p $SHARE_PATH/assets
mkdir -p $SHARE_PATH/assets/pictograms
mkdir -p $SHARE_PATH/operational
mkdir -p $SHARE_PATH/config
mkdir -p $SHARE_PATH/logs
mkdir -p $SHARE_PATH/generated_labels

echo -e "${GREEN}âœ“ Created subdirectories:${NC}"
echo "    - master_data/"
echo "    - master_data/unified_db/"
echo "    - master_data/original_data/"
echo "    - assets/"
echo "    - assets/pictograms/"
echo "    - operational/"
echo "    - config/"
echo "    - logs/"
echo "    - generated_labels/"

# ============================================================================
# STEP 3: Set Permissions
# ============================================================================
echo ""
echo -e "${YELLOW}â”â”â” STEP 3: Setting Permissions â”â”â”${NC}"

# Set ownership
chown -R $SGA_USER:$SGA_GROUP $SHARE_PATH
echo -e "${GREEN}âœ“ Ownership set to $SGA_USER:$SGA_GROUP${NC}"

# Set directory permissions (rwxrwxr-x)
find $SHARE_PATH -type d -exec chmod 775 {} \;
echo -e "${GREEN}âœ“ Directory permissions: 775${NC}"

# Set file permissions (rw-rw-r--)
find $SHARE_PATH -type f -exec chmod 664 {} \;
echo -e "${GREEN}âœ“ File permissions: 664${NC}"

# ============================================================================
# STEP 4: Configure Samba
# ============================================================================
echo ""
echo -e "${YELLOW}â”â”â” STEP 4: Configuring Samba Share â”â”â”${NC}"

# Detect Samba config file location
if [ -f /etc/samba/smb.conf ]; then
    SAMBA_CONF="/etc/samba/smb.conf"
elif [ -f /usr/local/samba/etc/smb.conf ]; then
    SAMBA_CONF="/usr/local/samba/etc/smb.conf"
else
    echo -e "${RED}âœ— Cannot find smb.conf${NC}"
    echo "Please add the share manually to your Samba configuration"
    exit 1
fi

echo "Samba config: $SAMBA_CONF"

# Check if share already exists
if grep -q "\[$SHARE_NAME\]" $SAMBA_CONF; then
    echo -e "${YELLOW}âš  Share [$SHARE_NAME] already exists in config${NC}"
    read -p "Do you want to replace it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove existing share section
        sed -i "/\[$SHARE_NAME\]/,/^\[/{ /^\[/!d; /\[$SHARE_NAME\]/d }" $SAMBA_CONF
        echo "Removed existing share configuration"
    else
        echo "Keeping existing configuration"
        SKIP_SAMBA_CONFIG=true
    fi
fi

if [ "$SKIP_SAMBA_CONFIG" != true ]; then
    # Backup config
    cp $SAMBA_CONF ${SAMBA_CONF}.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}âœ“ Backed up Samba config${NC}"

    # Add share configuration
    cat >> $SAMBA_CONF << EOF

# SGA Shared Database - Added $(date)
[$SHARE_NAME]
    comment = SGA Label System Shared Data
    path = $SHARE_PATH
    browseable = yes
    read only = no
    writable = yes
    guest ok = no
    valid users = @$SGA_GROUP
    create mask = 0664
    directory mask = 0775
    force user = $SGA_USER
    force group = $SGA_GROUP
    # Enable oplocks for better performance
    oplocks = yes
    level2 oplocks = yes
    # Locking for concurrent access
    locking = yes
    strict locking = auto
EOF

    echo -e "${GREEN}âœ“ Added share configuration to smb.conf${NC}"
fi

# ============================================================================
# STEP 5: Set Samba Password for SGA User
# ============================================================================
echo ""
echo -e "${YELLOW}â”â”â” STEP 5: Setting Samba Password â”â”â”${NC}"

echo "Please set the Samba password for user '$SGA_USER'"
echo "(This is the password clients will use to connect)"
echo ""

smbpasswd -a $SGA_USER

echo -e "${GREEN}âœ“ Samba password set${NC}"

# ============================================================================
# STEP 6: Restart Samba
# ============================================================================
echo ""
echo -e "${YELLOW}â”â”â” STEP 6: Restarting Samba Service â”â”â”${NC}"

# Detect service manager and restart
if command -v systemctl &> /dev/null; then
    systemctl restart smb nmb 2>/dev/null || systemctl restart smbd nmbd 2>/dev/null || true
    echo -e "${GREEN}âœ“ Samba restarted (systemctl)${NC}"
elif command -v service &> /dev/null; then
    service smb restart 2>/dev/null || service smbd restart 2>/dev/null || true
    service nmb restart 2>/dev/null || service nmbd restart 2>/dev/null || true
    echo -e "${GREEN}âœ“ Samba restarted (service)${NC}"
else
    echo -e "${YELLOW}âš  Please restart Samba manually${NC}"
fi

# ============================================================================
# STEP 7: Verify Share
# ============================================================================
echo ""
echo -e "${YELLOW}â”â”â” STEP 7: Verifying Share â”â”â”${NC}"

# Test Samba config
if testparm -s 2>/dev/null | grep -q "\[$SHARE_NAME\]"; then
    echo -e "${GREEN}âœ“ Share is configured correctly${NC}"
else
    echo -e "${YELLOW}âš  Could not verify share (testparm)${NC}"
fi

# List shares
echo ""
echo "Current Samba shares:"
smbclient -L localhost -N 2>/dev/null | grep -E "Disk|$SHARE_NAME" | head -15 || echo "(Could not list shares)"

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo -e "${GREEN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${GREEN}â•‘${NC}              âœ… SERVER SETUP COMPLETED!                     ${GREEN}â•‘${NC}"
echo -e "${GREEN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""
echo -e "${BLUE}Share Details:${NC}"
echo "  Name:     $SHARE_NAME"
echo "  Path:     $SHARE_PATH"
echo "  User:     $SGA_USER"
echo "  Access:   //$(hostname -I | awk '{print $1}')/$SHARE_NAME"
echo ""
echo -e "${BLUE}Next Steps (on client machines):${NC}"
echo "  1. Run: sudo ./setup_network_share.sh"
echo "  2. Enter username: $SGA_USER"
echo "  3. Enter the password you just set"
echo ""
echo -e "${BLUE}To test from a client:${NC}"
echo "  smbclient //20.0.1.9/$SHARE_NAME -U $SGA_USER"
echo ""
