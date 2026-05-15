#!/bin/bash
# Network Share Setup Script - Complete Configuration
# This script will set up the network share connection step-by-step

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
MOUNT_POINT="/mnt/sga_shared"
CREDENTIALS_FILE="/etc/sga-credentials"
CREDENTIALS_TEMPLATE="sga-credentials.template"
SERVER="20.0.1.9"
SHARE_NAME="sga_shared"

echo -e "${CYAN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${CYAN}â•‘${NC}     ${BOLD}SGA Network Share Setup - Complete Configuration${NC}      ${CYAN}â•‘${NC}"
echo -e "${CYAN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        return 1
    fi
    return 0
}

# Function to print step header
step_header() {
    echo ""
    echo -e "${BLUE}â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${BLUE}â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”${NC}"
}

# Function to print success message
success() {
    echo -e "${GREEN}âœ“${NC} $1"
}

# Function to print error message
error() {
    echo -e "${RED}âœ—${NC} $1"
}

# Function to print warning message
warning() {
    echo -e "${YELLOW}âš ${NC} $1"
}

# Function to print info message
info() {
    echo -e "${CYAN}â„¹${NC} $1"
}

# Check if script was run before
if [ -f "/tmp/sga_setup_completed" ]; then
    warning "Setup appears to have been run before."
    read -p "Do you want to run it again? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

# ============================================================================
# STEP 1: Check Prerequisites
# ============================================================================
step_header "STEP 1: Checking Prerequisites"

# Check if cifs-utils is installed
info "Checking for cifs-utils package..."
if ! dpkg -l | grep -q cifs-utils; then
    warning "cifs-utils not installed"
    echo "Installing cifs-utils is required for mounting SMB/CIFS shares."
    read -p "Install cifs-utils now? (requires sudo) (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y cifs-utils
        success "cifs-utils installed"
    else
        error "Cannot continue without cifs-utils"
        exit 1
    fi
else
    success "cifs-utils is installed"
fi

# Check server connectivity
info "Testing connection to server $SERVER..."
if ping -c 1 -W 2 $SERVER >/dev/null 2>&1; then
    success "Server $SERVER is reachable"
else
    error "Cannot reach server $SERVER"
    echo "Please check:"
    echo "  - Network connection"
    echo "  - Server IP address in shared_config.json"
    echo "  - Firewall settings"
    exit 1
fi

# Check if credentials template exists
info "Checking for credentials template..."
if [ ! -f "$CREDENTIALS_TEMPLATE" ]; then
    warning "Credentials template not found"
    info "Generating credentials template..."
    python3 network_share_manager.py --generate-scripts
fi
success "Credentials template found"

# ============================================================================
# STEP 2: Create Mount Point
# ============================================================================
step_header "STEP 2: Creating Mount Point"

if [ -d "$MOUNT_POINT" ]; then
    success "Mount point $MOUNT_POINT already exists"
else
    info "Creating mount point at $MOUNT_POINT..."
    sudo mkdir -p "$MOUNT_POINT"
    success "Mount point created"
fi

# Set proper permissions
sudo chmod 755 "$MOUNT_POINT"
success "Permissions set on mount point"

# ============================================================================
# STEP 3: Configure Credentials
# ============================================================================
step_header "STEP 3: Configuring Credentials"

# Check if credentials file already exists
if [ -f "$CREDENTIALS_FILE" ]; then
    warning "Credentials file already exists at $CREDENTIALS_FILE"
    read -p "Do you want to update it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Keeping existing credentials"
    else
        NEED_CREDENTIALS=true
    fi
else
    NEED_CREDENTIALS=true
fi

if [ "$NEED_CREDENTIALS" = true ]; then
    echo ""
    echo -e "${BOLD}Please enter the network share credentials:${NC}"
    echo ""
    
    # Get username (default: sga)
    read -p "Username [sga]: " USERNAME
    USERNAME=${USERNAME:-sga}
    
    # Get password
    echo -n "Password: "
    read -s PASSWORD
    echo ""
    
    # Get domain (default: WORKGROUP)
    read -p "Domain [WORKGROUP]: " DOMAIN
    DOMAIN=${DOMAIN:-WORKGROUP}
    
    # Create credentials file
    info "Creating credentials file..."
    sudo tee "$CREDENTIALS_FILE" > /dev/null <<EOF
username=$USERNAME
password=$PASSWORD
domain=$DOMAIN
EOF
    
    # Set proper permissions
    sudo chmod 600 "$CREDENTIALS_FILE"
    sudo chown root:root "$CREDENTIALS_FILE"
    
    success "Credentials file created and secured"
fi

# ============================================================================
# STEP 4: Mount the Network Share
# ============================================================================
step_header "STEP 4: Mounting Network Share"

# Check if already mounted
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    warning "Share is already mounted at $MOUNT_POINT"
    read -p "Do you want to remount it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Unmounting existing mount..."
        sudo umount "$MOUNT_POINT"
        success "Unmounted"
    else
        info "Keeping existing mount"
        ALREADY_MOUNTED=true
    fi
fi

if [ "$ALREADY_MOUNTED" != true ]; then
    info "Mounting //$SERVER/$SHARE_NAME to $MOUNT_POINT..."
    
    # Get current user's UID and GID
    USER_UID=$(id -u)
    USER_GID=$(id -g)
    
    # Mount the share
    if sudo mount -t cifs "//$SERVER/$SHARE_NAME" "$MOUNT_POINT" \
        -o credentials="$CREDENTIALS_FILE",rw,file_mode=0664,dir_mode=0775,uid=$USER_UID,gid=$USER_GID; then
        success "Network share mounted successfully!"
    else
        error "Failed to mount network share"
        echo ""
        echo "Common issues:"
        echo "  1. Wrong username/password - Run this script again"
        echo "  2. Share name incorrect - Check server configuration"
        echo "  3. Firewall blocking port 445 - Check network settings"
        echo "  4. Server not sharing the folder - Check server setup"
        echo ""
        exit 1
    fi
fi

# ============================================================================
# STEP 5: Verify Mount and Permissions
# ============================================================================
step_header "STEP 5: Testing Mount and Permissions"

# Test if mount point is accessible
info "Testing mount point accessibility..."
if [ -d "$MOUNT_POINT" ]; then
    success "Mount point is accessible"
else
    error "Mount point not accessible"
    exit 1
fi

# Test read access
info "Testing read access..."
if ls -la "$MOUNT_POINT" >/dev/null 2>&1; then
    success "Read access confirmed"
else
    error "Cannot read from mount point"
    exit 1
fi

# Test write access
info "Testing write access..."
TEST_FILE="$MOUNT_POINT/.sga_test_write"
if touch "$TEST_FILE" 2>/dev/null; then
    rm -f "$TEST_FILE"
    success "Write access confirmed"
else
    warning "Write access denied - may need to adjust permissions on server"
fi

# Show current contents
echo ""
info "Current contents of mount point:"
ls -lh "$MOUNT_POINT" 2>/dev/null | head -10 || echo "(empty or no access)"

# ============================================================================
# STEP 6: Run Python Diagnostic Test
# ============================================================================
step_header "STEP 6: Running Python Diagnostic Test"

info "Running network status check from Python..."
echo ""

python3 network_share_manager.py --status

echo ""

# ============================================================================
# STEP 7: Test from GUI Application
# ============================================================================
step_header "STEP 7: Testing GUI Integration"

info "Testing import of network modules..."
if python3 -c "
from network_share_manager import NetworkShareManager
from network_status_widget import NetworkStatusDialog
print('âœ“ Modules imported successfully')
manager = NetworkShareManager('shared_config.json')
status = manager.check_status()
print(f'âœ“ Mount status: {status[\"is_mounted\"]}')
print(f'âœ“ Can read: {status[\"can_read\"]}')
print(f'âœ“ Can write: {status[\"can_write\"]}')
" 2>&1; then
    success "Python integration test passed"
else
    error "Python integration test failed"
fi

# ============================================================================
# STEP 8: Configure Auto-Mount (Optional)
# ============================================================================
step_header "STEP 8: Configure Auto-Mount on Boot (Optional)"

echo ""
echo "Would you like to configure the network share to mount automatically on boot?"
echo "This adds an entry to /etc/fstab"
echo ""
read -p "Configure auto-mount? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Checking /etc/fstab for existing entry..."
    
    if grep -q "$MOUNT_POINT" /etc/fstab; then
        warning "Entry already exists in /etc/fstab"
    else
        info "Adding entry to /etc/fstab..."
        
        USER_UID=$(id -u)
        USER_GID=$(id -g)
        
        FSTAB_ENTRY="//$SERVER/$SHARE_NAME $MOUNT_POINT cifs credentials=$CREDENTIALS_FILE,rw,file_mode=0664,dir_mode=0775,uid=$USER_UID,gid=$USER_GID,_netdev 0 0"
        
        # Backup fstab
        sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
        
        # Add entry
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
        
        success "Auto-mount configured"
        info "Backup of /etc/fstab created"
    fi
else
    info "Skipping auto-mount configuration"
fi

# ============================================================================
# FINAL SUMMARY
# ============================================================================
echo ""
echo -e "${GREEN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${GREEN}â•‘${NC}                  ${BOLD}âœ… SETUP COMPLETED SUCCESSFULLY!${NC}                ${GREEN}â•‘${NC}"
echo -e "${GREEN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""

echo -e "${BOLD}Summary:${NC}"
echo -e "  ${GREEN}âœ“${NC} Server: $SERVER"
echo -e "  ${GREEN}âœ“${NC} Share: $SHARE_NAME"
echo -e "  ${GREEN}âœ“${NC} Mount Point: $MOUNT_POINT"
echo -e "  ${GREEN}âœ“${NC} Status: Mounted and accessible"

echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo "  1. Open the SGA application"
echo "  2. Go to 'Base de Datos' tab"
echo "  3. Click 'ðŸŒ Estado de Red' button"
echo "  4. You should see status: âœ… Connected"

echo ""
echo -e "${BOLD}Useful Commands:${NC}"
echo "  â€¢ Check status:     python3 network_share_manager.py --status"
echo "  â€¢ View diagnostics: python3 network_share_manager.py --diagnose"
echo "  â€¢ Unmount share:    sudo umount $MOUNT_POINT"
echo "  â€¢ Remount share:    ./mount_share.sh"
echo "  â€¢ Run this again:   sudo ./setup_network_share.sh"

echo ""

# Mark setup as completed
touch /tmp/sga_setup_completed

echo -e "${CYAN}â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""
