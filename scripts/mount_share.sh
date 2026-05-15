#!/bin/bash
# SGA Network Share Mount Script
# Generated automatically - customize as needed

set -e

MOUNT_POINT="/mnt/sga_shared"
SERVER="20.0.1.9"
SHARE="sga_shared"
USERNAME="sga"
CREDENTIALS_FILE="/etc/sga-credentials"

echo "Mounting SGA Network Share..."

# Check if already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "âœ“ Share already mounted at $MOUNT_POINT"
    exit 0
fi

# Create mount point if needed
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating mount point: $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT"
fi

# Check if credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "âš ï¸  Credentials file not found: $CREDENTIALS_FILE"
    echo "Creating template credentials file..."
    
    sudo tee "$CREDENTIALS_FILE" > /dev/null <<EOF
username=$USERNAME
password=YOUR_PASSWORD_HERE
domain=WORKGROUP
EOF
    sudo chmod 600 "$CREDENTIALS_FILE"
    
    echo "âŒ Please edit $CREDENTIALS_FILE and add the correct password"
    echo "Then run this script again"
    exit 1
fi

# Mount the share
echo "Mounting //$SERVER/$SHARE to $MOUNT_POINT..."
sudo mount -t cifs "//$SERVER/$SHARE" "$MOUNT_POINT" \
    -o credentials="$CREDENTIALS_FILE",rw,file_mode=0664,dir_mode=0775,uid=$(id -u),gid=$(id -g)

if mountpoint -q "$MOUNT_POINT"; then
    echo "âœ… Share mounted successfully!"
    echo "Testing access..."
    ls -la "$MOUNT_POINT" | head -5
else
    echo "âŒ Mount failed"
    exit 1
fi
