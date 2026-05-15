#!/bin/bash
# Client Setup Script for SGA Shared Deployment
# Run this on each client (admin/production) system

set -e

echo "=================================================="
echo "SGA Client Setup - Network Share Mount"
echo "=================================================="
echo ""

# Configuration - EDIT THESE VALUES
SERVER_IP="20.0.1.9"  # Your file server IP
SHARE_NAME="sga_shared"
MOUNT_POINT="/mnt/sga_shared"
SGA_USER="sga"
SYSTEM_ID="admin1"  # Change for each client: admin1, admin2, prod1, prod2
SYSTEM_ROLE="administrator"  # or "production"

echo "Configuration:"
echo "  Server:      //$SERVER_IP/$SHARE_NAME"
echo "  Mount Point: $MOUNT_POINT"
echo "  System ID:   $SYSTEM_ID"
echo "  System Role: $SYSTEM_ROLE"
echo ""

read -p "Continue with this configuration? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (sudo)"
    exit 1
fi

echo ""
echo "[1/5] Installing CIFS utilities..."
apt update
apt install -y cifs-utils

echo ""
echo "[2/5] Creating mount point..."
mkdir -p "$MOUNT_POINT"

echo ""
echo "[3/5] Creating credentials file..."
CRED_FILE="/etc/sga-cifs-credentials"

echo "Please enter Samba password for user '$SGA_USER':"
read -s SMB_PASSWORD

cat > "$CRED_FILE" << EOF
username=$SGA_USER
password=$SMB_PASSWORD
domain=WORKGROUP
EOF

chmod 600 "$CRED_FILE"
echo "Credentials saved to $CRED_FILE"

echo ""
echo "[4/5] Testing mount..."
mount -t cifs "//$SERVER_IP/$SHARE_NAME" "$MOUNT_POINT" \
    -o credentials="$CRED_FILE",uid=1000,gid=1000,file_mode=0664,dir_mode=0775

if [ $? -eq 0 ]; then
    echo "âœ“ Mount successful!"
    ls -la "$MOUNT_POINT"
else
    echo "âœ— Mount failed!"
    exit 1
fi

echo ""
echo "[5/5] Adding to /etc/fstab for persistent mount..."

# Remove old entry if exists
sed -i '\|//'$SERVER_IP'/'$SHARE_NAME'|d' /etc/fstab

# Add new entry
echo "//$SERVER_IP/$SHARE_NAME $MOUNT_POINT cifs credentials=$CRED_FILE,uid=1000,gid=1000,file_mode=0664,dir_mode=0775,_netdev 0 0" >> /etc/fstab

echo "âœ“ Added to /etc/fstab"

echo ""
echo "Creating SGA configuration..."
SGA_DIR="/opt/sga"
mkdir -p "$SGA_DIR"

cat > "$SGA_DIR/shared_config.json" << EOF
{
  "deployment_type": "shared",
  "system_id": "$SYSTEM_ID",
  "system_role": "$SYSTEM_ROLE",
  
  "shared_base_path": "$MOUNT_POINT",
  
  "paths": {
    "master_data": "\${shared_base_path}/master_data",
    "unified_db": "\${shared_base_path}/master_data/unified_db",
    "assets": "\${shared_base_path}/assets",
    "operational": "\${shared_base_path}/operational",
    "config": "\${shared_base_path}/config",
    "logs": "\${shared_base_path}/logs",
    "generated_labels": "\${shared_base_path}/generated_labels"
  },
  
  "files": {
    "label_queue": "\${operational}/label_queue.json",
    "history": "\${operational}/history.json",
    "users": "\${config}/users.json",
    "settings": "\${config}/settings.json",
    "barcode_db": "\${config}/mock_barcode_db.json"
  },
  
  "network": {
    "mount_check_enabled": true,
    "mount_path": "$MOUNT_POINT",
    "fallback_to_local": false
  },
  
  "file_locking": {
    "enabled": true,
    "lock_timeout_seconds": 10,
    "retry_delay_seconds": 0.1
  },
  
  "logging": {
    "level": "INFO",
    "file": "\${logs}/\${system_id}_\${date}.log"
  }
}
EOF

echo "âœ“ Configuration created at $SGA_DIR/shared_config.json"

echo ""
echo "=================================================="
echo "âœ“ Client Setup Complete!"
echo "=================================================="
echo ""
echo "Mount Information:"
echo "  Mounted at:  $MOUNT_POINT"
echo "  Persistent:  Yes (via /etc/fstab)"
echo "  System ID:   $SYSTEM_ID"
echo ""
echo "Next steps:"
echo "  1. Copy your SGA application to a local folder"
echo "  2. Copy $SGA_DIR/shared_config.json to your SGA folder"
echo "  3. Run: python3 shared_config_manager.py  (to test config)"
echo "  4. Start your SGA application"
echo ""
echo "To verify mount:"
echo "  mount | grep $MOUNT_POINT"
echo "  ls -la $MOUNT_POINT"
echo ""
echo "To unmount:"
echo "  sudo umount $MOUNT_POINT"
echo ""
